package main

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"math"
	"net"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"sync"
	"time"

	_ "github.com/go-sql-driver/mysql"
	"github.com/gorilla/mux"
	"github.com/gorilla/websocket"
)

var registerMutex sync.Mutex
var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	CheckOrigin: func(r *http.Request) bool {
		return true
	},
}

type LocationUpdate struct {
	DriverID  int     `json:"driver_id"`
	TripID    int     `json:"trip_id"`
	Latitude  float64 `json:"latitude"`
	Longitude float64 `json:"longitude"`
}

type TrackerHub struct {
	sync.Mutex
	Customers map[int][]*websocket.Conn
}

var hub = TrackerHub{
	Customers: make(map[int][]*websocket.Conn),
}

type DriverResponse struct {
	DriverID               int    `json:"driver_id"`
	FullName               string `json:"full_name"`
	PhoneNumber            string `json:"phone_number"`
	Address                string `json:"address"`
	AvatarUrl              string `json:"avatar_url"`
	DrivingLicenseFrontUrl string `json:"driving_license_front_url"`
	DrivingLicenseBackUrl  string `json:"driving_license_back_url"`
	IdentityCardFrontUrl   string `json:"identity_card_front_url"`
	IdentityCardBackUrl    string `json:"identity_card_back_url"`
}

type DriverRequestResponse struct {
	DriverResponse
	UserName                string `json:"user_name"`
	VehicleType             string `json:"vehicle_type"`
	LicensePlate            string `json:"license_plate"`
	LicensePlateExpiredDate string `json:"license_plate_expired_date"`
}

type AdminRatedDriverResponse struct {
	DriverID       int     `json:"driver_id"`
	FullName       string  `json:"full_name"`
	Rating         float64 `json:"rating"`
	CompletedTrips int     `json:"completed_trips"`
}

type AdminUserDocuments struct {
	DrivingLicenseFrontURL string `json:"driving_license_front_url"`
	DrivingLicenseBackURL  string `json:"driving_license_back_url"`
	IdentityCardFrontURL   string `json:"identity_card_front_url"`
	IdentityCardBackURL    string `json:"identity_card_back_url"`
}

type AdminUserResponse struct {
	ProfileID int                 `json:"profile_id"`
	FullName  string              `json:"full_name"`
	UserName  string              `json:"user_name"`
	Phone     string              `json:"phone_number"`
	Address   string              `json:"address"`
	Role      string              `json:"role"`
	Documents *AdminUserDocuments `json:"driver_documents,omitempty"`
}

type Trip struct {
	TripID       int     `json:"trip_id"`
	TripDistance int     `json:"trip_distance"`
	TripPrice    float64 `json:"trip_price"`
	CustomerID   int     `json:"customer_id"`
	DriverID     *int    `json:"driver_id"`
	TripStatusID int     `json:"trip_status_id"`
}

type Review struct {
	ReviewID int    `json:"review_id"`
	Comment  string `json:"comment"`
	Vote     int    `json:"vote"`
	DriverID int    `json:"driver_id"`
}

type Role struct {
	RoleId    int    `json:"row_id"`
	RoleValue string `json:"rown_value"`
	RoleState bool   `json:"role_state"`
}

var db *sql.DB

func getLocalIP() string {
	addrs, err := net.InterfaceAddrs()
	if err != nil {
		return "127.0.0.1"
	}
	for _, address := range addrs {
		if ipnet, ok := address.(*net.IPNet); ok && !ipnet.IP.IsLoopback() {
			if ipnet.IP.To4() != nil {
				return ipnet.IP.String()
			}
		}
	}
	return "127.0.0.1"
}

func parseNullString(ns sql.NullString) string {
	if !ns.Valid || ns.String == "" {
		return ""
	}
	return ns.String
}

func main() {
	var err error
	dsn := "root:root@tcp(127.0.0.1:3306)/mydb?parseTime=true"
	db, err = sql.Open("mysql", dsn)
	if err != nil {
		log.Fatal(err)
	}
	defer db.Close()
	err = db.Ping()
	if err != nil {
		log.Fatal("❌ Connect to MYSQL Failure: ", err)
	}

	fmt.Println("✅ Connect to MYSQL Success")

	r := mux.NewRouter()
	fileServer := http.FileServer(http.Dir("./image"))
	r.PathPrefix("/image/").Handler(http.StripPrefix("/image/", fileServer))

	//Role, VehicleType apis
	r.HandleFunc("/api/getRoles", getRole).Methods("GET")
	r.HandleFunc("/api/getVehicleType", getVehicleType).Methods("GET")
	r.HandleFunc("/api/user/price-config", getPriceConfig(db)).Methods("GET")

	// Admin APIs
	r.HandleFunc("/api/admin/drivers/requests", getDriverRequests).Methods("GET")
	r.HandleFunc("/api/admin/dashboard", getAdminDashboard).Methods("GET")
	r.HandleFunc("/api/admin/users", getAdminUsers).Methods("GET")
	r.HandleFunc("/api/admin/drivers", getAllDrivers).Methods("GET")
	r.HandleFunc("/api/admin/drivers/{id}/approve", approveDriver).Methods("POST")
	r.HandleFunc("/api/admin/bank-info", getAdminBankInfo).Methods("GET")
	r.HandleFunc("/api/admin/topup/{id}/review", reviewTopupRequest).Methods("PATCH")
	r.HandleFunc("/api/admin/topup/requests", getAllTopupRequests).Methods("GET")

	// User (Customer) APIs
	r.HandleFunc("/api/user/trips/book", bookTripV2).Methods("POST")
	r.HandleFunc("/api/user/trips/active", getActiveCustomerTripV2).Methods("GET")
	r.HandleFunc("/api/trips/history", getTripHistoryByProfile).Methods("GET")
	r.HandleFunc("/api/user/trips/{id}/cancel", cancelTrip).Methods("POST")
	r.HandleFunc("/api/user/drivers/review", reviewDriver).Methods("POST")

	// Driver APIs
	r.HandleFunc("/api/driver/trips/{id}/accept", acceptTripV2).Methods("POST")
	r.HandleFunc("/api/driver/trips/active", getActiveDriverTripV2).Methods("GET")
	r.HandleFunc("/api/driver/trips/{id}/complete", completeTripV2).Methods("POST")
	r.HandleFunc("/api/driver/trips/{id}/start", startTripV2).Methods("POST")
	r.HandleFunc("/api/driver/{id}/register-info", getRegisterRequest).Methods("GET")
	r.HandleFunc("/api/driver/{id}/register-info", resubmitDriverRegisterInfo).Methods("POST")
	r.HandleFunc("/api/driver/topup", createTopupRequest).Methods("POST")
	r.HandleFunc("/api/driver/{id}/wallet", getDriverWallet).Methods("GET")
	r.HandleFunc("/api/driver/{id}/topup/requests", getDriverTopupRequests).Methods("GET")
	r.HandleFunc("/api/topup/{id}", getTopupRequestDetail).Methods("GET")
	r.HandleFunc("/api/driver/topup/{id}/update", updateTopupRequest).Methods("PUT", "POST")
	r.HandleFunc("/api/driver/trips/{id}/cancel", driverCancelTrip).Methods("POST")

	// For Driver, User, Admin
	r.HandleFunc("/api/user/login", loginUser).Methods("POST")
	r.HandleFunc("/api/user/register", registerUser).Methods("POST")
	r.HandleFunc("/api/{id}/bank-info", getBankInfo).Methods("GET")
	r.HandleFunc("/api/{id}/bank-info", updateBankInfo).Methods("POST")
	r.HandleFunc("/api/{id}/profile", getUserProfile).Methods("GET")
	r.HandleFunc("/api/{id}/profile", updateUserProfile).Methods("POST", "PATCH")

	// Customer connect to listener location of driver realtime
	r.HandleFunc("/ws/user/track/{trip_id}", handleUserTrackingV2).Methods("GET")

	// Driver push location to server realtime
	r.HandleFunc("/ws/driver/location", handleDriverLocationStreamV2).Methods("GET")
	r.HandleFunc("/ws/driver/trips", handleDriverTripNotificationsV2).Methods("GET")

	localIP := getLocalIP()
	port := ":8080"
	fmt.Printf("🚀 Server đang chạy trên mạng Wi-Fi!\n")
	fmt.Printf("📱 Địa chỉ để nhập vào App: http://%s%s\n", localIP, port)
	log.Fatal(http.ListenAndServe("0.0.0.0:8080", r))

}

func handleUserTracking(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	tripID, err := strconv.Atoi(vars["trip_id"])
	if err != nil {
		w.WriteHeader(http.StatusBadRequest)
		return
	}

	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Println("Lỗi nâng cấp kết nối khách hàng:", err)
		return
	}

	hub.Lock()
	hub.Customers[tripID] = append(hub.Customers[tripID], conn)
	hub.Unlock()

	log.Printf("Khách hàng đã kết nối thành công để theo dõi Trip ID: %d\n", tripID)

	defer func() {
		conn.Close()
		hub.Lock()
		conns := hub.Customers[tripID]
		for i, c := range conns {
			if c == conn {
				hub.Customers[tripID] = append(conns[:i], conns[i+1:]...)
				break
			}
		}
		hub.Unlock()
		log.Printf("Khách hàng ngắt kết nối theo dõi Trip ID: %d\n", tripID)
	}()

	for {
		if _, _, err := conn.ReadMessage(); err != nil {
			break
		}
	}
}

func handleDriverLocationStream(w http.ResponseWriter, r *http.Request) {
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Println("Lỗi nâng cấp kết nối tài xế:", err)
		return
	}
	defer conn.Close()

	log.Println("Tài xế đã thiết lập kết nối luồng tọa độ GPS real-time")

	for {
		_, message, err := conn.ReadMessage()
		if err != nil {
			log.Println("Tài xế ngắt kết nối stream vị trí:", err)
			break
		}

		var update LocationUpdate
		if err := json.Unmarshal(message, &update); err != nil {
			log.Println("Dữ liệu GPS gửi lên sai định dạng:", err)
			continue
		}

		hub.Lock()
		customers, exists := hub.Customers[update.TripID]
		hub.Unlock()

		if exists {
			for _, clientConn := range customers {
				err := clientConn.WriteMessage(websocket.TextMessage, message)
				if err != nil {
					log.Println("Lỗi gửi tọa độ tới thiết bị khách hàng, bỏ qua kết nối lỗi.")
				}
			}
		}
	}
}

// Get all role active
func getRole(w http.ResponseWriter, r *http.Request) {
	const active int = 1
	rows, _ := db.Query("SELECT * FROM Role where state = 1")
	var roles []Role
	for rows.Next() {
		var roleId int
		var roleName string
		var roleValueRaw int
		err := rows.Scan(&roleId, &roleName, &roleValueRaw)
		if err != nil {
			continue
		}
		roles = append(roles, Role{
			roleId,
			roleName,
			roleValueRaw == active,
		})
	}
	if err := rows.Err(); err != nil {
		http.Error(w, "Lỗi xử lý luồng dữ liệu cơ sở dữ liệu", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	w.Header().Set("Content-Type", "application/json")
	apiResponse := struct {
		Data []Role `json:"data"`
	}{
		Data: roles,
	}
	jsonData, _ := json.Marshal(apiResponse)
	w.WriteHeader(http.StatusOK)
	w.Write(jsonData)
}

func getVehicleType(w http.ResponseWriter, r *http.Request) {
	type VehicleTypeResponse struct {
		ID   int    `json:"id"`
		Name string `json:"name"`
	}
	rows, _ := db.Query("SELECT id, type FROM VehicleType")
	var vehicleTypes []VehicleTypeResponse

	for rows.Next() {
		var id int
		var typeName string
		err := rows.Scan(&id, &typeName)
		if err != nil {
			continue
		}
		vehicleTypes = append(vehicleTypes, VehicleTypeResponse{
			ID:   id,
			Name: typeName,
		})
	}

	if err := rows.Err(); err != nil {
		http.Error(w, "Lỗi xử lý luồng dữ liệu cơ sở dữ liệu", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	w.Header().Set("Content-Type", "application/json")
	apiResponse := struct {
		Data []VehicleTypeResponse `json:"data"`
	}{
		Data: vehicleTypes,
	}

	jsonData, _ := json.Marshal(apiResponse)
	w.WriteHeader(http.StatusOK)
	w.Write(jsonData)
}

// --- Admin Handlers ---
func getAdminUsers(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	rows, err := db.QueryContext(r.Context(), `
		SELECT p.profile_id, p.full_name, p.user_name, p.phone_number, p.address,
			r.role_value, d.driver_id,
			d.driving_license_front_side, d.driving_license_back_side,
			d.front_side_of_the_identity_card, d.the_back_of_the_identity_card
		FROM Profile p
		JOIN Role r ON r.role_id = p.role_id
		LEFT JOIN Driver d ON d.driver_id = p.profile_id
		ORDER BY p.profile_id DESC
	`)
	if err != nil {
		log.Printf("Error loading admin users: %v", err)
		http.Error(w, `{"error":"Could not load users"}`, http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	users := []AdminUserResponse{}
	imageURL := func(value sql.NullString) string {
		if !value.Valid || value.String == "" {
			return ""
		}
		return fmt.Sprintf("http://%s/image/%s", r.Host, value.String)
	}
	for rows.Next() {
		var user AdminUserResponse
		var fullName, phone, address sql.NullString
		var driverID sql.NullInt64
		var licenseFront, licenseBack, identityFront, identityBack sql.NullString
		if err := rows.Scan(&user.ProfileID, &fullName, &user.UserName, &phone,
			&address, &user.Role, &driverID, &licenseFront, &licenseBack,
			&identityFront, &identityBack); err != nil {
			log.Printf("Error scanning admin user: %v", err)
			http.Error(w, `{"error":"Could not load users"}`, http.StatusInternalServerError)
			return
		}
		user.FullName = parseNullString(fullName)
		if user.FullName == "" {
			user.FullName = user.UserName
		}
		user.Phone = parseNullString(phone)
		user.Address = parseNullString(address)
		if driverID.Valid {
			user.Documents = &AdminUserDocuments{
				DrivingLicenseFrontURL: imageURL(licenseFront),
				DrivingLicenseBackURL:  imageURL(licenseBack),
				IdentityCardFrontURL:   imageURL(identityFront),
				IdentityCardBackURL:    imageURL(identityBack),
			}
		}
		users = append(users, user)
	}
	if err := rows.Err(); err != nil {
		log.Printf("Error iterating admin users: %v", err)
		http.Error(w, `{"error":"Could not load users"}`, http.StatusInternalServerError)
		return
	}
	json.NewEncoder(w).Encode(users)
}

func getAdminDashboard(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	var totalDrivers, approvedDrivers, pendingRequests int
	err := db.QueryRowContext(r.Context(), `
		SELECT
			(SELECT COUNT(*) FROM Driver),
			(SELECT COUNT(*) FROM Driver WHERE active = 1),
			(SELECT COUNT(*) FROM Driver d WHERE d.active = 0
				AND NOT EXISTS (SELECT 1 FROM ReasonReject rr WHERE rr.driver_id = d.driver_id))
	`).Scan(&totalDrivers, &approvedDrivers, &pendingRequests)
	if err != nil {
		log.Printf("Error loading admin driver counts: %v", err)
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(map[string]string{"error": "Could not load dashboard"})
		return
	}

	rows, err := db.QueryContext(r.Context(), `
		SELECT d.driver_id,
			COALESCE(NULLIF(TRIM(p.full_name), ''), p.user_name),
			AVG(rt.vote) AS rating,
			(SELECT COUNT(*) FROM Trip completed
				WHERE completed.driver_id = d.driver_id AND completed.trip_status_id = 4) AS completed_trips
		FROM Driver d
		JOIN Profile p ON p.profile_id = d.driver_id
		JOIN Trip t ON t.driver_id = d.driver_id AND t.trip_status_id = 4
		JOIN ReviewTrip rt ON rt.trip_id = t.trip_id AND rt.vote BETWEEN 1 AND 5
		WHERE d.active = 1
		GROUP BY d.driver_id, p.full_name, p.user_name
		ORDER BY rating DESC, completed_trips DESC, d.driver_id ASC
		LIMIT 6
	`)
	if err != nil {
		log.Printf("Error loading top rated drivers: %v", err)
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(map[string]string{"error": "Could not load dashboard"})
		return
	}
	defer rows.Close()

	topRatedDrivers := []AdminRatedDriverResponse{}
	for rows.Next() {
		var driver AdminRatedDriverResponse
		if err := rows.Scan(&driver.DriverID, &driver.FullName, &driver.Rating, &driver.CompletedTrips); err != nil {
			log.Printf("Error scanning top rated driver: %v", err)
			w.WriteHeader(http.StatusInternalServerError)
			json.NewEncoder(w).Encode(map[string]string{"error": "Could not load dashboard"})
			return
		}
		topRatedDrivers = append(topRatedDrivers, driver)
	}
	if err := rows.Err(); err != nil {
		log.Printf("Error iterating top rated drivers: %v", err)
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(map[string]string{"error": "Could not load dashboard"})
		return
	}

	json.NewEncoder(w).Encode(map[string]interface{}{
		"data": map[string]interface{}{
			"total_drivers":     totalDrivers,
			"approved_drivers":  approvedDrivers,
			"pending_requests":  pendingRequests,
			"top_rated_drivers": topRatedDrivers,
		},
	})
}

func getDriverRequests(w http.ResponseWriter, r *http.Request) {
	baseImgURL := fmt.Sprintf("http://%s:8080/image/", getLocalIP())
	query := `
		SELECT 
			p.profile_id, p.full_name, p.phone_number, p.address, p.image,
			d.driving_license_front_side, d.driving_license_back_side, 
			d.front_side_of_the_identity_card, d.the_back_of_the_identity_card,
			p.user_name, v.type, d.licensePlate, d.licensePlateExpiredDate
		FROM Profile p
		INNER JOIN Driver d ON p.profile_id = d.driver_id
		INNER JOIN VehicleType v ON v.id = d.vehicleType_id
		WHERE d.active = 0
		  AND NOT EXISTS (
			SELECT 1 FROM ReasonReject rr WHERE rr.driver_id = d.driver_id
		  )
		ORDER BY d.driver_id DESC
	`
	rows, err := db.Query(query)
	if err != nil {
		log.Printf("❌ Lỗi Query Database: %v", err)
		http.Error(w, "Lỗi kết nối hoặc truy vấn cơ sở dữ liệu", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	drivers := []DriverRequestResponse{}
	log.Print("Request get all request drivers")

	for rows.Next() {
		var fullName, phoneNumber, address, avatar, licenseFront, licenseBack, idFront, idBack sql.NullString
		var userName, vehicleType, licensePlate string
		var licensePlateExpiredDate time.Time
		var driverID int
		err := rows.Scan(
			&driverID, &fullName, &phoneNumber, &address, &avatar,
			&licenseFront, &licenseBack, &idFront, &idBack,
			&userName, &vehicleType, &licensePlate, &licensePlateExpiredDate,
		)
		if err != nil {
			log.Print(err)
			w.WriteHeader(http.StatusInternalServerError)
			json.NewEncoder(w).Encode(map[string]string{"error": "Đã xảy ra lỗi server"})
			return
		}
		d := DriverResponse{
			DriverID:               driverID,
			FullName:               parseNullString(fullName),
			PhoneNumber:            parseNullString(phoneNumber),
			Address:                parseNullString(address),
			AvatarUrl:              baseImgURL + parseNullString(avatar),
			DrivingLicenseFrontUrl: baseImgURL + parseNullString(licenseFront),
			DrivingLicenseBackUrl:  baseImgURL + parseNullString(licenseBack),
			IdentityCardFrontUrl:   baseImgURL + parseNullString(idFront),
			IdentityCardBackUrl:    baseImgURL + parseNullString(idBack),
		}
		drivers = append(drivers, DriverRequestResponse{
			DriverResponse:          d,
			UserName:                userName,
			VehicleType:             vehicleType,
			LicensePlate:            licensePlate,
			LicensePlateExpiredDate: licensePlateExpiredDate.Format("2006-01-02"),
		})
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(drivers)
}

func getAllDrivers(w http.ResponseWriter, r *http.Request) {
	baseImgURL := fmt.Sprintf("http://%s:8080/image/", getLocalIP())
	query := `
		SELECT 
			p.profile_id, p.full_name, p.phone_number, p.address, p.image,
			d.driving_license_front_side, d.driving_license_back_side, 
			d.front_side_of_the_identity_card, d.the_back_of_the_identity_card
		FROM Profile p
		INNER JOIN Driver d ON p.profile_id = d.driver_id
		WHERE d.active = 1
	`
	rows, err := db.Query(query)
	if err != nil {
		log.Printf("❌ Lỗi Query Database: %v", err)
		http.Error(w, "Lỗi kết nối hoặc truy vấn cơ sở dữ liệu", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var drivers []DriverResponse
	log.Print("Request get all drivers")

	for rows.Next() {
		var fullName, phoneNumber, address, avatar, licenseFront, licenseBack, idFront, idBack sql.NullString
		var driverID int
		err := rows.Scan(
			&driverID, &fullName, &phoneNumber, &address, &avatar,
			&licenseFront, &licenseBack, &idFront, &idBack,
		)
		if err != nil {
			log.Print(err)
			w.WriteHeader(http.StatusInternalServerError)
			json.NewEncoder(w).Encode(map[string]string{"error": "Đã xảy ra lỗi server"})
			return
		}
		d := DriverResponse{
			DriverID:               driverID,
			FullName:               parseNullString(fullName),
			PhoneNumber:            parseNullString(phoneNumber),
			Address:                parseNullString(address),
			AvatarUrl:              baseImgURL + parseNullString(avatar),
			DrivingLicenseFrontUrl: baseImgURL + parseNullString(licenseFront),
			DrivingLicenseBackUrl:  baseImgURL + parseNullString(licenseBack),
			IdentityCardFrontUrl:   baseImgURL + parseNullString(idFront),
			IdentityCardBackUrl:    baseImgURL + parseNullString(idBack),
		}
		drivers = append(drivers, d)
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(drivers)
}

func approveDriver(w http.ResponseWriter, r *http.Request) {
	type ApproveDriverRequest struct {
		DriverID int    `json:"driver_id"`
		Status   bool   `json:"status"`
		Reason   string `json:"reason"`
	}
	type ApprovedDriverDetail struct {
		DriverID int    `json:"driver_id"`
		Active   bool   `json:"active"`
		Message  string `json:"message"`
	}
	w.Header().Set("Content-Type", "application/json")

	var req ApproveDriverRequest
	err := json.NewDecoder(r.Body).Decode(&req)
	if err != nil {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(struct {
			Error string `json:"error"`
		}{Error: "Dữ liệu JSON không hợp lệ"})
		return
	}
	routeID, err := strconv.Atoi(mux.Vars(r)["id"])
	if err != nil || routeID <= 0 || routeID != req.DriverID {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(map[string]string{"error": "driver_id không khớp với URL"})
		return
	}
	req.Reason = strings.TrimSpace(req.Reason)

	if !req.Status && req.Reason == "" {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(struct {
			Error string `json:"error"`
		}{Error: "Vui lòng cung cấp lý do từ chối hồ sơ (reason)"})
		return
	}

	ctx := context.Background()
	tx, err := db.BeginTx(ctx, nil)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(struct {
			Error string `json:"error"`
		}{Error: "Không thể khởi tạo tiến trình xử lý dữ liệu"})
		return
	}
	defer tx.Rollback()

	var existingID int
	err = tx.QueryRowContext(ctx,
		"SELECT driver_id FROM Driver WHERE driver_id = ? FOR UPDATE", req.DriverID,
	).Scan(&existingID)
	if err == sql.ErrNoRows {
		w.WriteHeader(http.StatusNotFound)
		json.NewEncoder(w).Encode(map[string]string{"error": "Không tìm thấy tài xế"})
		return
	}
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(map[string]string{"error": "Không thể kiểm tra tài xế"})
		return
	}

	activeValue := 0
	if req.Status {
		activeValue = 1
	}

	updateQuery := "UPDATE Driver SET active = ? WHERE driver_id = ?"
	_, err = tx.ExecContext(ctx, updateQuery, activeValue, req.DriverID)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(struct {
			Error string `json:"error"`
		}{Error: "Lỗi hệ thống khi cập nhật trạng thái tài xế"})
		return
	}

	msg := ""
	if req.Status {
		deleteReasonQuery := "DELETE FROM ReasonReject WHERE driver_id = ?"
		_, err = tx.ExecContext(ctx, deleteReasonQuery, req.DriverID)
		if err != nil {
			w.WriteHeader(http.StatusInternalServerError)
			json.NewEncoder(w).Encode(map[string]interface{}{"error": "Lỗi hệ thống khi xóa lịch sử lý do từ chối"})
			return
		}
		walletQuery := "INSERT INTO DriverWallet (driver_id, money) VALUES (?, 0) ON DUPLICATE KEY UPDATE money = money"
		_, err = tx.ExecContext(ctx, walletQuery, req.DriverID)
		if err != nil {
			w.WriteHeader(http.StatusInternalServerError)
			json.NewEncoder(w).Encode(map[string]interface{}{"error": "Lỗi hệ thống khi tạo ví cho tài xế"})
			return
		}

		msg = "Tài xế đã được phê duyệt hoạt động và khởi tạo ví thành công"
	} else {
		insertReasonQuery := "INSERT INTO ReasonReject (reason, driver_id) VALUES (?, ?)"
		_, err = tx.ExecContext(ctx, insertReasonQuery, req.Reason, req.DriverID)
		if err != nil {
			w.WriteHeader(http.StatusInternalServerError)
			json.NewEncoder(w).Encode(map[string]interface{}{"error": "Lỗi hệ thống khi lưu trữ lý do từ chối"})
			return
		}
		msg = "Đã từ chối hồ sơ tài xế và ghi nhận lý do thành công"
	}

	if err = tx.Commit(); err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(struct {
			Error string `json:"error"`
		}{Error: "Lỗi hệ thống khi xác nhận hoàn tất dữ liệu"})
		return
	}

	resultDetail := ApprovedDriverDetail{
		DriverID: req.DriverID,
		Active:   req.Status,
		Message:  msg,
	}

	apiResponse := struct {
		Data ApprovedDriverDetail `json:"data"`
	}{
		Data: resultDetail,
	}

	jsonData, _ := json.Marshal(apiResponse)
	w.WriteHeader(http.StatusOK)
	w.Write(jsonData)
}

func bookTrip(w http.ResponseWriter, r *http.Request) {
	type BookTripRequest struct {
		CustomerID    int     `json:"customer_id"`
		TripDistance  int     `json:"trip_distance"`
		TripLatitude  float64 `json:"trip_latitude"`
		TripLongitude float64 `json:"trip_longitude"`
	}

	type BookTripResponseDetail struct {
		TripID        int     `json:"trip_id"`
		CustomerID    int     `json:"customer_id"`
		TripDistance  int     `json:"trip_distance"`
		TripPrice     float64 `json:"trip_price"`
		TripStatusID  int     `json:"trip_status_id"`
		StatusText    string  `json:"status_text"`
		TripLatitude  float64 `json:"trip_latitude"`
		TripLongitude float64 `json:"trip_longitude"`
		Message       string  `json:"message"`
	}
	w.Header().Set("Content-Type", "application/json")

	var req BookTripRequest
	err := json.NewDecoder(r.Body).Decode(&req)
	if err != nil {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(map[string]string{"error": "Dữ liệu JSON không hợp lệ"})
		return
	}

	if req.CustomerID == 0 || req.TripDistance <= 0 || req.TripLatitude == 0 || req.TripLongitude == 0 {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(map[string]string{"error": "Vui lòng nhập đầy đủ các trường yêu cầu"})
		return
	}

	var pricePerKm int
	priceQuery := "SELECT price_per_km FROM PriceConfig WHERE ? >= `from` AND ? <= `to` LIMIT 1"
	err = db.QueryRow(priceQuery, req.TripDistance, req.TripDistance).Scan(&pricePerKm)

	if err == sql.ErrNoRows {
		pricePerKm = 10000
	} else if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(map[string]string{"error": "Lỗi hệ thống khi tính toán giá tiền"})
		return
	}

	totalPrice := float64(req.TripDistance * pricePerKm)

	ctx := context.Background()
	tx, err := db.BeginTx(ctx, nil)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(map[string]string{"error": "Lỗi hệ thống khởi tạo tiến trình"})
		return
	}
	defer tx.Rollback()

	defaultStatusID := 1

	insertTripQuery := `
		INSERT INTO Trip (trip_distance, trip_price, customer_id, driver_id, trip_status_id, trip_latitude, trip_longitude)
		VALUES (?, ?, ?, NULL, ?, ?, ?)
	`
	res, err := tx.ExecContext(ctx, insertTripQuery, req.TripDistance, totalPrice, req.CustomerID, defaultStatusID, req.TripLatitude, req.TripLongitude)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(map[string]string{"error": "Lỗi hệ thống khi lưu chuyến đi"})
		return
	}

	lastInsertId, _ := res.LastInsertId()
	newTripID := int(lastInsertId)

	updateCustomerLoc := "UPDATE Customer SET latitude = ?, longitude = ? WHERE customer_id = ?"
	_, _ = tx.ExecContext(ctx, updateCustomerLoc, req.TripLatitude, req.TripLongitude, req.CustomerID)

	var statusText string
	statusQuery := "SELECT status FROM TripStatus WHERE trip_status_id = ?"
	err = tx.QueryRowContext(ctx, statusQuery, defaultStatusID).Scan(&statusText)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(map[string]string{"error": "Lỗi hệ thống khi tra cứu tên trạng thái chuyến đi"})
		return
	}

	if err = tx.Commit(); err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(map[string]string{"error": "Lỗi hệ thống xác nhận chuyến đi"})
		return
	}

	apiResponse := struct {
		Data BookTripResponseDetail `json:"data"`
	}{
		Data: BookTripResponseDetail{
			TripID:        newTripID,
			CustomerID:    req.CustomerID,
			TripDistance:  req.TripDistance,
			TripPrice:     totalPrice,
			TripStatusID:  defaultStatusID,
			StatusText:    statusText,
			TripLatitude:  req.TripLatitude,
			TripLongitude: req.TripLongitude,
			Message:       "Tạo chuyến đi thành công! Đang tìm kiếm tài xế...",
		},
	}

	jsonData, _ := json.Marshal(apiResponse)
	w.WriteHeader(http.StatusCreated)
	w.Write(jsonData)
}

func cancelTrip(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")

	tripID, err := strconv.Atoi(mux.Vars(r)["id"])
	if err != nil || tripID <= 0 {
		tripJSONErrorV2(w, http.StatusBadRequest, "trip_id không hợp lệ")
		return
	}

	type CancelTripRequest struct {
		CustomerID int `json:"customer_id"`
	}

	var req CancelTripRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.CustomerID <= 0 {
		tripJSONErrorV2(w, http.StatusBadRequest, "Vui lòng truyền customer_id hợp lệ")
		return
	}

	tx, err := db.BeginTx(r.Context(), nil)
	if err != nil {
		tripJSONErrorV2(w, http.StatusInternalServerError, "Không thể khởi tạo giao dịch hủy chuyến")
		return
	}
	defer tx.Rollback()

	var lockedCustomerID int
	err = tx.QueryRowContext(r.Context(), `
		SELECT customer_id FROM Customer WHERE customer_id = ? FOR UPDATE
	`, req.CustomerID).Scan(&lockedCustomerID)
	if err == sql.ErrNoRows {
		tripJSONErrorV2(w, http.StatusNotFound, "Không tìm thấy khách hàng")
		return
	}
	if err != nil {
		tripJSONErrorV2(w, http.StatusInternalServerError, "Không thể kiểm tra khách hàng trước khi hủy chuyến")
		return
	}

	var currentCustomerID, tripStatusID int
	var driverID sql.NullInt64

	err = tx.QueryRowContext(r.Context(), `
		SELECT customer_id, trip_status_id, driver_id
		FROM Trip WHERE trip_id = ? FOR UPDATE
	`, tripID).Scan(&currentCustomerID, &tripStatusID, &driverID)

	if err == sql.ErrNoRows {
		tripJSONErrorV2(w, http.StatusNotFound, "Không tìm thấy chuyến đi")
		return
	}
	if err != nil {
		tripJSONErrorV2(w, http.StatusInternalServerError, "Lỗi hệ thống khi kiểm tra chuyến đi")
		return
	}

	if currentCustomerID != req.CustomerID {
		tripJSONErrorV2(w, http.StatusForbidden, "Bạn không có quyền hủy chuyến đi của người khác")
		return
	}

	if tripStatusID != tripStatusPendingV2 && tripStatusID != tripStatusAcceptedV2 {
		tripJSONErrorV2(w, http.StatusConflict, "Chuyến đi đang di chuyển hoặc đã kết thúc, không thể hủy")
		return
	}

	_, err = tx.ExecContext(r.Context(), `
		UPDATE Trip
		SET trip_status_id = ?, time = NOW()
		WHERE trip_id = ?
	`, tripStatusCancelV2, tripID)
	if err != nil {
		tripJSONErrorV2(w, http.StatusInternalServerError, "Không thể cập nhật trạng thái hủy chuyến")
		return
	}

	if err := tx.Commit(); err != nil {
		tripJSONErrorV2(w, http.StatusInternalServerError, "Không thể xác nhận hoàn tất hủy chuyến")
		return
	}

	cancelEvent := map[string]interface{}{
		"type":    "trip_cancelled_by_customer",
		"trip_id": tripID,
	}
	broadcastCustomerTripV2(tripID, cancelEvent)

	if driverID.Valid {
		sendDriverMessageV2(int(driverID.Int64), cancelEvent)
	}

	if tripStatusID == tripStatusPendingV2 {
		broadcastAllDriversV2(map[string]interface{}{
			"type":    "trip_taken",
			"trip_id": tripID,
		})
	}

	w.WriteHeader(http.StatusOK)
	_ = json.NewEncoder(w).Encode(map[string]interface{}{
		"message": "Khách hàng hủy chuyến đi thành công",
		"trip_id": tripID,
	})
}

func driverCancelTrip(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")

	tripID, err := strconv.Atoi(mux.Vars(r)["id"])
	if err != nil || tripID <= 0 {
		tripJSONErrorV2(w, http.StatusBadRequest, "trip_id không hợp lệ")
		return
	}

	type DriverCancelRequest struct {
		DriverID int `json:"driver_id"`
	}

	var req DriverCancelRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.DriverID <= 0 {
		tripJSONErrorV2(w, http.StatusBadRequest, "Vui lòng truyền driver_id hợp lệ")
		return
	}

	tx, err := db.BeginTx(r.Context(), nil)
	if err != nil {
		tripJSONErrorV2(w, http.StatusInternalServerError, "Không thể khởi tạo giao dịch tài xế hủy chuyến")
		return
	}
	defer tx.Rollback()

	var tripStatusID int
	var currentDriverID sql.NullInt64

	err = tx.QueryRowContext(r.Context(), `
		SELECT trip_status_id, driver_id FROM Trip WHERE trip_id = ? FOR UPDATE
	`, tripID).Scan(&tripStatusID, &currentDriverID)

	if err == sql.ErrNoRows {
		tripJSONErrorV2(w, http.StatusNotFound, "Không tìm thấy chuyến đi")
		return
	}
	if err != nil {
		tripJSONErrorV2(w, http.StatusInternalServerError, "Lỗi hệ thống khi kiểm tra chuyến đi")
		return
	}

	if !currentDriverID.Valid || int(currentDriverID.Int64) != req.DriverID {
		tripJSONErrorV2(w, http.StatusForbidden, "Bạn không phải tài xế đang tiếp nhận chuyến đi này")
		return
	}

	if tripStatusID != tripStatusAcceptedV2 {
		tripJSONErrorV2(w, http.StatusConflict, "Chuyến đi không ở trạng thái chờ đón hoặc đã bắt đầu di chuyển, không thể hủy")
		return
	}

	_, err = tx.ExecContext(r.Context(), `
		UPDATE Trip SET driver_id = NULL, trip_status_id = ? WHERE trip_id = ?
	`, tripStatusPendingV2, tripID)
	if err != nil {
		tripJSONErrorV2(w, http.StatusInternalServerError, "Không thể cập nhật giải phóng chuyến đi")
		return
	}

	if err := tx.Commit(); err != nil {
		tripJSONErrorV2(w, http.StatusInternalServerError, "Không thể xác nhận hoàn tất hủy tiếp nhận")
		return
	}

	broadcastCustomerTripV2(tripID, map[string]interface{}{
		"type":      "driver_cancelled_trip",
		"trip_id":   tripID,
		"driver_id": req.DriverID,
	})

	var tripDistance int
	var tripPrice float64
	var customerID int
	var tripLat, tripLng, destLat, destLng float64

	_ = db.QueryRow(`
		SELECT customer_id, trip_distance, trip_price, trip_latitude, trip_longitude, destination_latitude, destination_longitude 
		FROM Trip WHERE trip_id = ?
	`, tripID).Scan(&customerID, &tripDistance, &tripPrice, &tripLat, &tripLng, &destLat, &destLng)

	broadcastAllDriversV2(map[string]interface{}{
		"type": "new_trip",
		"data": map[string]interface{}{
			"trip_id":               tripID,
			"customer_id":           customerID,
			"trip_distance":         tripDistance,
			"trip_price":            tripPrice,
			"trip_latitude":         tripLat,
			"trip_longitude":        tripLng,
			"destination_latitude":  destLat,
			"destination_longitude": destLng,
		},
	})

	w.WriteHeader(http.StatusOK)
	_ = json.NewEncoder(w).Encode(map[string]interface{}{
		"message": "Tài xế hủy tiếp nhận chuyến đi thành công, chuyến đi đã được đưa về hàng chờ",
		"trip_id": tripID,
	})
}

func reviewDriver(w http.ResponseWriter, r *http.Request) {
	type ReviewTripRequest struct {
		TripID  int    `json:"trip_id"`
		Vote    int    `json:"vote"`
		Comment string `json:"comment"`
	}
	type ReviewResponseDetail struct {
		Message string `json:"message"`
		TripID  int    `json:"trip_id"`
	}
	if r.Method != http.MethodPost {
		w.WriteHeader(http.StatusMethodNotAllowed)
		json.NewEncoder(w).Encode(map[string]string{"error": "Phương thức không được hỗ trợ"})
		return
	}

	var req ReviewTripRequest
	err := json.NewDecoder(r.Body).Decode(&req)
	if err != nil {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(map[string]string{"error": "Dữ liệu JSON không hợp lệ"})
		return
	}

	if req.TripID <= 0 || req.Vote < 1 || req.Vote > 5 {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(map[string]string{"error": "Dữ liệu trip_id hoặc số sao vote (1-5) không hợp lệ"})
		return
	}

	log.Printf("Request review trip ID: %d", req.TripID)

	tx, err := db.Begin()
	if err != nil {
		log.Printf("❌ Lỗi Begin Transaction: %v", err)
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(map[string]string{"error": "Đã xảy ra lỗi server"})
		return
	}
	defer tx.Rollback()

	var tripStatusID int
	queryCheckTrip := "SELECT trip_status_id FROM Trip WHERE trip_id = ?"
	err = tx.QueryRow(queryCheckTrip, req.TripID).Scan(&tripStatusID)
	if err != nil {
		if err == sql.ErrNoRows {
			w.WriteHeader(http.StatusNotFound)
			json.NewEncoder(w).Encode(map[string]string{"error": "Không tìm thấy chuyến đi này"})
			return
		}
		log.Printf("❌ Lỗi kiểm tra Trip: %v", err)
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(map[string]string{"error": "Đã xảy ra lỗi server"})
		return
	}

	if tripStatusID != 4 {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(map[string]string{"error": "Chuyến đi chưa hoàn thành, không thể đánh giá"})
		return
	}

	var existID int
	queryCheckReview := "SELECT reviewId FROM ReviewTrip WHERE trip_id = ? LIMIT 1"
	err = tx.QueryRow(queryCheckReview, req.TripID).Scan(&existID)
	if err != nil && err != sql.ErrNoRows {
		log.Printf("❌ Lỗi kiểm tra Review: %v", err)
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(map[string]string{"error": "Đã xảy ra lỗi server"})
		return
	}
	if err == nil {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(map[string]string{"error": "Chuyến đi này đã được đánh giá trước đó"})
		return
	}

	queryInsert := "INSERT INTO ReviewTrip (comment, vote, trip_id) VALUES (?, ?, ?)"
	_, err = tx.Exec(queryInsert, req.Comment, req.Vote, req.TripID)
	if err != nil {
		log.Printf("❌ Lỗi Insert ReviewTrip: %v", err)
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(map[string]string{"error": "Không thể lưu đánh giá"})
		return
	}

	if err = tx.Commit(); err != nil {
		log.Printf("❌ Lỗi Commit Transaction: %v", err)
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(map[string]string{"error": "Đã xảy ra lỗi server"})
		return
	}

	apiResponse := struct {
		Data ReviewResponseDetail `json:"data"`
	}{
		Data: ReviewResponseDetail{
			Message: "Đánh giá chuyến đi thành công!",
			TripID:  req.TripID,
		},
	}

	w.Header().Set("Content-Type", "application/json")
	jsonData, _ := json.Marshal(apiResponse)
	w.WriteHeader(http.StatusOK)
	w.Write(jsonData)
}

func acceptTrip(w http.ResponseWriter, r *http.Request) {
}

func completeTrip(w http.ResponseWriter, r *http.Request) {

}

// --- Login/Register Handlers ---
func loginUser(w http.ResponseWriter, r *http.Request) {
	type LoginRequest struct {
		UserName string `json:"user_name"`
		Password string `json:"password"`
	}

	type LoginResponseDetail struct {
		ProfileID int    `json:"profile_id"`
		UserName  string `json:"user_name"`
		Role      string `json:"role"`
		Status    string `json:"status"`
		Message   string `json:"message"`
	}

	w.Header().Set("Content-Type", "application/json")

	if r.Method != http.MethodPost {
		w.WriteHeader(http.StatusMethodNotAllowed)
		json.NewEncoder(w).Encode(map[string]string{"error": "Phương thức không được hỗ trợ"})
		return
	}

	var req LoginRequest
	err := json.NewDecoder(r.Body).Decode(&req)
	if err != nil {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(map[string]string{"error": "Dữ liệu JSON không hợp lệ"})
		return
	}

	if req.UserName == "" || req.Password == "" {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(map[string]string{"error": "Vui lòng nhập đầy đủ user_name và password"})
		return
	}

	var profileID int
	var dbPassword, dbRoleValue string

	queryProfile := `
		SELECT p.profile_id, p.password, r.role_value 
		FROM Profile p
		INNER JOIN Role r ON p.role_id = r.role_id
		WHERE p.user_name = ?
		LIMIT 2
	`
	invalidCredentialsError := map[string]string{"error": "Tài khoản hoặc mật khẩu không chính xác"}
	rows, err := db.Query(queryProfile, req.UserName)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(map[string]string{"error": "Lỗi hệ thống khi kiểm tra thông tin tài khoản"})
		return
	}
	defer rows.Close()
	if !rows.Next() {
		if rows.Err() != nil {
			w.WriteHeader(http.StatusInternalServerError)
			json.NewEncoder(w).Encode(map[string]string{"error": "Lỗi hệ thống khi kiểm tra thông tin tài khoản"})
			return
		}
		w.WriteHeader(http.StatusUnauthorized)
		json.NewEncoder(w).Encode(invalidCredentialsError)
		return
	}
	if err := rows.Scan(&profileID, &dbPassword, &dbRoleValue); err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(map[string]string{"error": "Lỗi hệ thống khi kiểm tra thông tin tài khoản"})
		return
	}
	if rows.Next() {
		w.WriteHeader(http.StatusConflict)
		json.NewEncoder(w).Encode(map[string]string{"error": "Tên đăng nhập bị trùng; vui lòng liên hệ quản trị viên"})
		return
	}
	if rows.Err() != nil {
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(map[string]string{"error": "Lỗi hệ thống khi kiểm tra thông tin tài khoản"})
		return
	}

	if dbPassword != req.Password {
		w.WriteHeader(http.StatusUnauthorized)
		json.NewEncoder(w).Encode(invalidCredentialsError)
		return
	}

	loginStatus := "APPROVED"
	msg := "Đăng nhập thành công"

	if dbRoleValue == "DRIVER" {
		var active int
		queryDriver := "SELECT active FROM Driver WHERE driver_id = ?"
		err = db.QueryRow(queryDriver, profileID).Scan(&active)
		if err != nil {
			w.WriteHeader(http.StatusInternalServerError)
			json.NewEncoder(w).Encode(map[string]string{"error": "Lỗi hệ thống khi kiểm tra trạng thái tài xế"})
			return
		}

		if active == 0 {
			var rejectReason string
			queryReject := "SELECT reason FROM ReasonReject WHERE driver_id = ? ORDER BY id DESC LIMIT 1"
			err = db.QueryRow(queryReject, profileID).Scan(&rejectReason)

			switch err {
			case sql.ErrNoRows:
				loginStatus = "PENDING"
				msg = "Tài khoản đang chờ phê duyệt"
			case nil:
				loginStatus = "REJECTED"
				msg = rejectReason
			default:
				w.WriteHeader(http.StatusInternalServerError)
				json.NewEncoder(w).Encode(map[string]string{"error": "Lỗi hệ thống khi tra cứu lịch sử từ chối"})
				return
			}
		}
	}

	apiResponse := struct {
		Data LoginResponseDetail `json:"data"`
	}{
		Data: LoginResponseDetail{
			ProfileID: profileID,
			UserName:  req.UserName,
			Role:      dbRoleValue,
			Status:    loginStatus,
			Message:   msg,
		},
	}

	jsonData, _ := json.Marshal(apiResponse)
	w.WriteHeader(http.StatusOK)
	w.Write(jsonData)
}

func registerUser(w http.ResponseWriter, r *http.Request) {
	type RegisterRequest struct {
		UserName                   string `json:"user_name"`
		Password                   string `json:"password"`
		Role                       string `json:"role"`
		PhoneNumber                string `json:"phone_number"`
		VehicleID                  string `json:"vehicle_id,omitempty"`
		LicensePlate               string `json:"license_plate,omitempty"`
		LicensePlateExpiredDate    string `json:"license_plate_expired_date,omitempty"`
		DrivingLicenseFrontSide    string `json:"driving_license_front_side,omitempty"`
		DrivingLicenseBackSide     string `json:"driving_license_back_side,omitempty"`
		FrontSideOfTheIdentityCard string `json:"front_side_of_the_identity_card,omitempty"`
		TheBackOfTheIdentityCard   string `json:"the_back_of_the_identity_card,omitempty"`
	}

	type RegisterResponseDetail struct {
		ProfileID int    `json:"profile_id"`
		UserName  string `json:"user_name"`
		Role      string `json:"role"`
		Message   string `json:"message"`
	}

	w.Header().Set("Content-Type", "application/json")

	if r.Method != http.MethodPost {
		w.WriteHeader(http.StatusMethodNotAllowed)
		json.NewEncoder(w).Encode(map[string]string{"error": "Phương thức không được hỗ trợ"})
		return
	}

	err := r.ParseMultipartForm(10 << 20)
	if err != nil {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(map[string]string{"error": "Không thể xử lý dữ liệu form-data hoặc file quá lớn"})
		return
	}

	userName := strings.TrimSpace(r.FormValue("user_name"))
	fullName := strings.TrimSpace(r.FormValue("full_name"))
	if fullName == "" {
		fullName = userName
	}
	password := r.FormValue("password")
	role := r.FormValue("role")
	phoneNumber := r.FormValue("phone_number")

	if userName == "" || password == "" || role == "" || phoneNumber == "" {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(map[string]string{"error": "Vui lòng nhập đầy đủ user_name, password, role và phone_number"})
		return
	}

	registerMutex.Lock()
	defer registerMutex.Unlock()

	ctx := context.Background()
	tx, err := db.BeginTx(ctx, nil)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(map[string]string{"error": "Lỗi hệ thống khởi tạo tiến trình"})
		return
	}
	defer tx.Rollback()

	var userExists int
	checkUserQuery := "SELECT COUNT(*) FROM Profile WHERE user_name = ?"
	err = tx.QueryRowContext(ctx, checkUserQuery, userName).Scan(&userExists)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(map[string]string{"error": "Lỗi kiểm tra tài khoản"})
		return
	}
	if userExists > 0 {
		w.WriteHeader(http.StatusConflict)
		json.NewEncoder(w).Encode(map[string]string{"error": "Tên tài khoản (userName) này đã tồn tại trên hệ thống"})
		return
	}

	var phoneExists int
	checkPhoneQuery := "SELECT COUNT(*) FROM Profile WHERE phone_number = ?"
	err = tx.QueryRowContext(ctx, checkPhoneQuery, phoneNumber).Scan(&phoneExists)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(map[string]string{"error": "Lỗi kiểm tra số điện thoại"})
		return
	}
	if phoneExists > 0 {
		w.WriteHeader(http.StatusConflict)
		json.NewEncoder(w).Encode(map[string]string{"error": "Số điện thoại này đã được đăng ký trên hệ thống"})
		return
	}

	var roleID int
	roleQuery := "SELECT role_id FROM Role WHERE role_value = ?"
	err = tx.QueryRowContext(ctx, roleQuery, role).Scan(&roleID)
	if err != nil {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(map[string]string{"error": "Quyền tài khoản (role) không hợp lệ"})
		return
	}

	profileQuery := "INSERT INTO Profile (full_name, user_name, password, phone_number, role_id) VALUES (?, ?, ?, ?, ?)"
	res, err := tx.ExecContext(ctx, profileQuery, fullName, userName, password, phoneNumber, roleID)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(map[string]string{"error": "Lỗi ghi nhận hồ sơ người dùng"})
		return
	}

	lastInsertId, _ := res.LastInsertId()
	newID := int(lastInsertId)

	msg := ""

	switch role {
	case "CUSTOMER":
		customerQuery := "INSERT INTO Customer (customer_id) VALUES (?)"
		_, err = tx.ExecContext(ctx, customerQuery, newID)
		if err != nil {
			w.WriteHeader(http.StatusInternalServerError)
			json.NewEncoder(w).Encode(map[string]string{"error": "Lỗi lưu hồ sơ khách hàng"})
			return
		}
		msg = "Đăng ký tài khoản Khách hàng thành công!"

	case "DRIVER":
		vehicleID := r.FormValue("vehicle_id")
		licensePlate := r.FormValue("license_plate")
		licensePlateExpiredDate := r.FormValue("license_plate_expired_date")

		if vehicleID == "" || licensePlate == "" || licensePlateExpiredDate == "" {
			w.WriteHeader(http.StatusBadRequest)
			json.NewEncoder(w).Encode(map[string]string{"error": "Tài xế bắt buộc phải nhập vehicle_id và license_plate"})
			return
		}

		saveFormFile := func(formKey, targetName string) error {
			file, _, err := r.FormFile(formKey)
			if err != nil {
				return fmt.Errorf("thiếu file hoặc lỗi đọc file: %s", formKey)
			}
			defer file.Close()

			outPath := filepath.Join(".", "image", targetName)
			outFile, err := os.Create(outPath)
			if err != nil {
				return err
			}
			defer outFile.Close()

			_, err = io.Copy(outFile, file)
			return err
		}

		licenseFrontName := fmt.Sprintf("%d_license_front_side.jpg", newID)
		licenseBackName := fmt.Sprintf("%d_driver_license_back_side.jpg", newID)
		idFrontName := fmt.Sprintf("%d_driver_front_side.jpg", newID)
		idBackName := fmt.Sprintf("%d_driver_back_side.png", newID)

		if err = saveFormFile("driving_license_front_side", licenseFrontName); err != nil {
			w.WriteHeader(http.StatusBadRequest)
			json.NewEncoder(w).Encode(map[string]string{"error": err.Error()})
			return
		}
		if err = saveFormFile("driving_license_back_side", licenseBackName); err != nil {
			w.WriteHeader(http.StatusBadRequest)
			json.NewEncoder(w).Encode(map[string]string{"error": err.Error()})
			return
		}
		if err = saveFormFile("front_side_of_the_identity_card", idFrontName); err != nil {
			w.WriteHeader(http.StatusBadRequest)
			json.NewEncoder(w).Encode(map[string]string{"error": err.Error()})
			return
		}
		if err = saveFormFile("the_back_of_the_identity_card", idBackName); err != nil {
			w.WriteHeader(http.StatusBadRequest)
			json.NewEncoder(w).Encode(map[string]string{"error": err.Error()})
			return
		}

		driverQuery := `
			INSERT INTO Driver (
				driver_id, vehicleType_id, licensePlate, driving_license_front_side,
				driving_license_back_side, front_side_of_the_identity_card, 
				the_back_of_the_identity_card, active, licensePlateExpiredDate
			) VALUES (?, ?, ?, ?, ?, ?, ?, 0, ?)
		`
		_, err = tx.ExecContext(ctx, driverQuery, newID, vehicleID, licensePlate, licenseFrontName, licenseBackName, idFrontName, idBackName, licensePlateExpiredDate)
		if err != nil {
			w.WriteHeader(http.StatusInternalServerError)
			json.NewEncoder(w).Encode(map[string]string{"error": "Lỗi lưu hồ sơ tài xế và phương tiện vào cơ sở dữ liệu"})
			return
		}
		msg = "Đăng ký tài khoản Tài xế và tải lên hồ sơ ảnh thành công! Vui lòng chờ phê duyệt."
	}

	if err = tx.Commit(); err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(map[string]string{"error": "Lỗi hệ thống khi hoàn tất đăng ký"})
		return
	}

	apiResponse := struct {
		Data map[string]interface{} `json:"data"`
	}{
		Data: map[string]interface{}{
			"profile_id": newID,
			"user_name":  userName,
			"role":       role,
			"message":    msg,
		},
	}

	jsonData, _ := json.Marshal(apiResponse)
	w.WriteHeader(http.StatusCreated)
	w.Write(jsonData)
}

// Get driver bank information
func getBankInfo(w http.ResponseWriter, r *http.Request) {
	type BankInfoResponse struct {
		ProfileID         int    `json:"profile_id"`
		BankName          string `json:"bank_name"`
		BankAccountNumber string `json:"bank_account_number"`
		BankAccountName   string `json:"bank_account_name"`
		QRCode            string `json:"bank_qr_code"`
	}

	w.Header().Set("Content-Type", "application/json")
	vars := mux.Vars(r)
	profileID, err := strconv.Atoi(vars["id"])

	if err != nil || profileID <= 0 {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(map[string]string{
			"error": "profile_id không hợp lệ",
		})
		return
	}

	query := `
        SELECT
            profile_id,
            bank_name,
            bank_account_number,
            bank_account_name,
            bank_qr_code
        FROM Profile
        WHERE profile_id = ?
    `

	var bankInfo BankInfoResponse
	var bankName, accountNumber, accountName, qrCode sql.NullString

	err = db.QueryRow(query, profileID).Scan(
		&bankInfo.ProfileID,
		&bankName,
		&accountNumber,
		&accountName,
		&qrCode,
	)

	if err != nil {
		if err == sql.ErrNoRows {
			w.WriteHeader(http.StatusNotFound)
			json.NewEncoder(w).Encode(map[string]string{
				"error": "Không tìm thấy thông tin ngân hàng",
			})
			return
		}

		log.Printf("Lỗi lấy thông tin ngân hàng: %v", err)
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(map[string]string{
			"error": "Lỗi hệ thống khi lấy thông tin ngân hàng",
		})
		return
	}

	bankInfo.BankName = parseNullString(bankName)
	bankInfo.BankAccountNumber = parseNullString(accountNumber)
	bankInfo.BankAccountName = parseNullString(accountName)
	bankInfo.QRCode = parseNullString(qrCode)

	apiResponse := struct {
		Data BankInfoResponse `json:"data"`
	}{
		Data: bankInfo,
	}

	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(apiResponse)
}

func updateBankInfo(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	if r.Method != http.MethodPost {
		w.WriteHeader(http.StatusMethodNotAllowed)
		json.NewEncoder(w).Encode(map[string]string{
			"error": "Phương thức không được hỗ trợ",
		})
		return
	}

	profileID := mux.Vars(r)["id"]

	id, err := strconv.Atoi(profileID)
	if err != nil || id <= 0 {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(map[string]string{
			"error": "profile_id không hợp lệ",
		})
		return
	}

	r.Body = http.MaxBytesReader(w, r.Body, 10<<20)

	err = r.ParseMultipartForm(10 << 20)
	if err != nil {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(map[string]string{
			"error": "Dữ liệu không hợp lệ hoặc file vượt quá dung lượng cho phép",
		})
		return
	}

	var oldQRCode sql.NullString

	err = db.QueryRow(
		`SELECT bank_qr_code FROM Profile WHERE profile_id = ?`,
		id,
	).Scan(&oldQRCode)

	if err != nil {
		if err == sql.ErrNoRows {
			w.WriteHeader(http.StatusNotFound)
			json.NewEncoder(w).Encode(map[string]string{
				"error": "Không tìm thấy tài khoản tài xế",
			})
			return
		}

		log.Printf("Lỗi lấy thông tin Profile: %v", err)

		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(map[string]string{
			"error": "Lỗi hệ thống",
		})
		return
	}

	var setClauses []string
	var args []interface{}

	bankName := strings.TrimSpace(r.FormValue("bank_name"))
	bankAccountNumber := strings.TrimSpace(r.FormValue("bank_account_number"))
	bankAccountName := strings.TrimSpace(r.FormValue("bank_account_name"))

	if bankName != "" {
		setClauses = append(setClauses, "bank_name = ?")
		args = append(args, bankName)
	}

	if bankAccountNumber != "" {
		setClauses = append(setClauses, "bank_account_number = ?")
		args = append(args, bankAccountNumber)
	}

	if bankAccountName != "" {
		setClauses = append(setClauses, "bank_account_name = ?")
		args = append(args, bankAccountName)
	}

	var newQRFileName string
	var newQRFilePath string
	var tempQRFilePath string
	var backupQRFilePath string

	uploadedFiles := r.MultipartForm.File["bank_qr_code"]

	if len(uploadedFiles) > 0 {
		header := uploadedFiles[0]

		file, err := header.Open()
		if err != nil {
			w.WriteHeader(http.StatusBadRequest)
			json.NewEncoder(w).Encode(map[string]string{
				"error": "Không thể đọc file QR code",
			})
			return
		}
		defer file.Close()

		ext := strings.ToLower(filepath.Ext(header.Filename))

		allowedExts := map[string]bool{
			".jpg":  true,
			".jpeg": true,
			".png":  true,
			".webp": true,
		}

		if !allowedExts[ext] {
			w.WriteHeader(http.StatusBadRequest)
			json.NewEncoder(w).Encode(map[string]string{
				"error": "Chỉ hỗ trợ ảnh JPG, JPEG, PNG hoặc WEBP",
			})
			return
		}

		newQRFileName = fmt.Sprintf("%d_bank%s", id, ext)
		newQRFilePath = filepath.Join("image", newQRFileName)

		if err := os.MkdirAll("image", os.ModePerm); err != nil {
			log.Printf("Lỗi tạo thư mục image: %v", err)

			w.WriteHeader(http.StatusInternalServerError)
			json.NewEncoder(w).Encode(map[string]string{
				"error": "Không thể tạo thư mục lưu ảnh",
			})
			return
		}

		tempFile, err := os.CreateTemp("image", "qr_temp_*")
		if err != nil {
			w.WriteHeader(http.StatusInternalServerError)
			json.NewEncoder(w).Encode(map[string]string{
				"error": "Không thể tạo file QR code",
			})
			return
		}

		tempQRFilePath = tempFile.Name()

		_, copyErr := io.Copy(tempFile, file)
		closeErr := tempFile.Close()

		if copyErr != nil || closeErr != nil {
			os.Remove(tempQRFilePath)

			w.WriteHeader(http.StatusInternalServerError)
			json.NewEncoder(w).Encode(map[string]string{
				"error": "Không thể lưu file QR code",
			})
			return
		}

		setClauses = append(setClauses, "bank_qr_code = ?")
		args = append(args, newQRFileName)
	}

	if len(setClauses) == 0 {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(map[string]string{
			"error": "Không có thông tin nào được gửi để cập nhật",
		})
		return
	}

	if tempQRFilePath != "" {

		if _, err := os.Stat(newQRFilePath); err == nil {

			backupFile, err := os.CreateTemp("image", "qr_backup_*")
			if err != nil {
				os.Remove(tempQRFilePath)

				w.WriteHeader(http.StatusInternalServerError)
				json.NewEncoder(w).Encode(map[string]string{
					"error": "Không thể backup QR code cũ",
				})
				return
			}

			backupQRFilePath = backupFile.Name()
			backupFile.Close()
			os.Remove(backupQRFilePath)

			if err := os.Rename(newQRFilePath, backupQRFilePath); err != nil {
				os.Remove(tempQRFilePath)

				w.WriteHeader(http.StatusInternalServerError)
				json.NewEncoder(w).Encode(map[string]string{
					"error": "Không thể backup QR code cũ",
				})
				return
			}

		} else if !os.IsNotExist(err) {
			os.Remove(tempQRFilePath)

			w.WriteHeader(http.StatusInternalServerError)
			json.NewEncoder(w).Encode(map[string]string{
				"error": "Không thể truy cập QR code cũ",
			})
			return
		}

		if err := os.Rename(tempQRFilePath, newQRFilePath); err != nil {

			if backupQRFilePath != "" {
				os.Rename(backupQRFilePath, newQRFilePath)
			}

			os.Remove(tempQRFilePath)

			w.WriteHeader(http.StatusInternalServerError)
			json.NewEncoder(w).Encode(map[string]string{
				"error": "Không thể lưu QR code",
			})
			return
		}
	}

	query := fmt.Sprintf(
		"UPDATE Profile SET %s WHERE profile_id = ?",
		strings.Join(setClauses, ", "),
	)

	args = append(args, id)

	result, err := db.Exec(query, args...)

	if err != nil {
		log.Printf("Lỗi update bank information: %v", err)

		if newQRFilePath != "" {
			os.Remove(newQRFilePath)
		}

		if backupQRFilePath != "" {
			os.Rename(backupQRFilePath, newQRFilePath)
		}

		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(map[string]string{
			"error": "Không thể cập nhật thông tin ngân hàng",
		})
		return
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		log.Printf("Lỗi lấy RowsAffected: %v", err)
	}

	if backupQRFilePath != "" {
		os.Remove(backupQRFilePath)
	}

	if newQRFileName != "" && oldQRCode.Valid {
		oldFileName := filepath.Base(oldQRCode.String)

		if oldFileName != "" && oldFileName != newQRFileName {
			oldFilePath := filepath.Join("image", oldFileName)
			os.Remove(oldFilePath)
		}
	}

	w.WriteHeader(http.StatusOK)

	json.NewEncoder(w).Encode(map[string]interface{}{
		"success": true,
		"message": "Cập nhật thông tin ngân hàng thành công",
		"data": map[string]interface{}{
			"profile_id":          id,
			"bank_name":           bankName,
			"bank_account_number": bankAccountNumber,
			"bank_account_name":   bankAccountName,
			"bank_qr_code":        newQRFileName,
		},
		"rows_affected": rowsAffected,
	})
}

func getRegisterRequest(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	driverID, err := strconv.Atoi(mux.Vars(r)["id"])
	if err != nil || driverID <= 0 {
		http.Error(w, `{"error":"driver_id không hợp lệ"}`, http.StatusBadRequest)
		return
	}

	var (
		phoneNumber             sql.NullString
		vehicleID               sql.NullInt64
		licensePlate            sql.NullString
		licensePlateExpiredDate time.Time
		licenseFront            sql.NullString
		licenseBack             sql.NullString
		identityFront           sql.NullString
		identityBack            sql.NullString
		reason                  string
	)

	query := `
		SELECT
			p.phone_number,
			d.vehicleType_id,
			d.licensePlate,
			d.licensePlateExpiredDate,
			d.driving_license_front_side,
			d.driving_license_back_side,
			d.front_side_of_the_identity_card,
			d.the_back_of_the_identity_card,
			rr.reason
		FROM Driver d
		INNER JOIN Profile p ON p.profile_id = d.driver_id
		INNER JOIN ReasonReject rr ON rr.driver_id = d.driver_id
		WHERE d.driver_id = ?
		  AND d.active = 0
		ORDER BY rr.id DESC
		LIMIT 1
	`

	err = db.QueryRow(query, driverID).Scan(
		&phoneNumber,
		&vehicleID,
		&licensePlate,
		&licensePlateExpiredDate,
		&licenseFront,
		&licenseBack,
		&identityFront,
		&identityBack,
		&reason,
	)

	if err == sql.ErrNoRows {
		http.Error(w, `{"error":"Không tìm thấy hồ sơ tài xế bị từ chối"}`, http.StatusNotFound)
		return
	}
	if err != nil {
		log.Printf("Lỗi lấy thông tin hồ sơ tài xế: %v", err)
		http.Error(w, `{"error":"Lỗi hệ thống khi lấy thông tin hồ sơ"}`, http.StatusInternalServerError)
		return
	}

	baseImgURL := fmt.Sprintf("http://%s:8080/image/", getLocalIP())

	imageURL := func(filename sql.NullString) string {
		if !filename.Valid || filename.String == "" {
			return ""
		}
		return baseImgURL + filename.String
	}

	response := map[string]interface{}{
		"driver_id":                       driverID,
		"phone_number":                    parseNullString(phoneNumber),
		"vehicle_id":                      vehicleID.Int64,
		"license_plate":                   parseNullString(licensePlate),
		"license_plate_expired_date":      licensePlateExpiredDate.Format("2006-01-02"),
		"driving_license_front_side":      imageURL(licenseFront),
		"driving_license_back_side":       imageURL(licenseBack),
		"front_side_of_the_identity_card": imageURL(identityFront),
		"the_back_of_the_identity_card":   imageURL(identityBack),
		"reason":                          reason,
	}

	json.NewEncoder(w).Encode(map[string]interface{}{
		"data": response,
	})
}

func resubmitDriverRegisterInfo(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	if r.Method != http.MethodPost {
		w.WriteHeader(http.StatusMethodNotAllowed)
		json.NewEncoder(w).Encode(map[string]string{
			"error": "Phương thức không được hỗ trợ",
		})
		return
	}

	err := r.ParseMultipartForm(25 << 20)
	if err != nil {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(map[string]string{
			"error": "Không thể xử lý dữ liệu form-data hoặc file quá lớn",
		})
		return
	}

	driverID, err := strconv.Atoi(mux.Vars(r)["id"])
	if err != nil || driverID <= 0 {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(map[string]string{
			"error": "driver_id không hợp lệ",
		})
		return
	}

	tx, err := db.Begin()
	if err != nil {
		log.Println("Lỗi khởi tạo transaction:", err)
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(map[string]string{
			"error": "Lỗi hệ thống",
		})
		return
	}
	defer tx.Rollback()

	var active int
	err = tx.QueryRow(
		"SELECT active FROM Driver WHERE driver_id = ? FOR UPDATE",
		driverID,
	).Scan(&active)

	if err != nil {
		if err == sql.ErrNoRows {
			w.WriteHeader(http.StatusNotFound)
			json.NewEncoder(w).Encode(map[string]string{
				"error": "Không tìm thấy tài xế",
			})
			return
		}

		log.Println("Lỗi kiểm tra tài xế:", err)
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(map[string]string{
			"error": "Lỗi hệ thống khi kiểm tra tài xế",
		})
		return
	}

	if active != 0 {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(map[string]string{
			"error": "Tài khoản tài xế không ở trạng thái cần đăng ký lại",
		})
		return
	}

	var rejectCount int
	err = tx.QueryRow(
		"SELECT COUNT(*) FROM ReasonReject WHERE driver_id = ?",
		driverID,
	).Scan(&rejectCount)

	if err != nil {
		log.Println("Lỗi kiểm tra ReasonReject:", err)
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(map[string]string{
			"error": "Lỗi kiểm tra trạng thái hồ sơ",
		})
		return
	}

	if rejectCount == 0 {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(map[string]string{
			"error": "Hồ sơ tài xế không có trạng thái bị từ chối",
		})
		return
	}

	phoneNumber := r.FormValue("phone_number")

	if phoneNumber != "" {
		_, err = tx.Exec(
			"UPDATE Profile SET phone_number = ? WHERE profile_id = ?",
			phoneNumber,
			driverID,
		)

		if err != nil {
			log.Println("Lỗi cập nhật số điện thoại:", err)
			w.WriteHeader(http.StatusInternalServerError)
			json.NewEncoder(w).Encode(map[string]string{
				"error": "Lỗi cập nhật số điện thoại",
			})
			return
		}
	}

	var driverUpdates []string
	var driverArgs []interface{}

	vehicleID := r.FormValue("vehicle_id")
	if vehicleID != "" {
		driverUpdates = append(driverUpdates, "vehicleType_id = ?")
		driverArgs = append(driverArgs, vehicleID)
	}

	licensePlate := r.FormValue("license_plate")
	if licensePlate != "" {
		driverUpdates = append(driverUpdates, "licensePlate = ?")
		driverArgs = append(driverArgs, licensePlate)
	}

	licensePlateExpiredDate := r.FormValue("license_plate_expired_date")
	if licensePlateExpiredDate != "" {
		driverUpdates = append(driverUpdates, "licensePlateExpiredDate = ?")
		driverArgs = append(driverArgs, licensePlateExpiredDate)
	}

	err = os.MkdirAll("./image", 0755)
	if err != nil {
		log.Println("Lỗi tạo thư mục image:", err)
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(map[string]string{
			"error": "Không thể truy cập thư mục lưu ảnh",
		})
		return
	}

	saveImage := func(formKey, columnName, targetName string) error {
		if r.MultipartForm == nil {
			return nil
		}

		files := r.MultipartForm.File[formKey]

		if len(files) == 0 {
			return nil
		}

		file, err := files[0].Open()
		if err != nil {
			return fmt.Errorf("không thể đọc file %s: %v", formKey, err)
		}
		defer file.Close()

		outPath := filepath.Join(".", "image", targetName)

		outFile, err := os.Create(outPath)
		if err != nil {
			return fmt.Errorf("không thể tạo file %s: %v", targetName, err)
		}

		_, copyErr := io.Copy(outFile, file)
		closeErr := outFile.Close()

		if copyErr != nil {
			return fmt.Errorf("lỗi ghi file %s: %v", targetName, copyErr)
		}

		if closeErr != nil {
			return fmt.Errorf("lỗi đóng file %s: %v", targetName, closeErr)
		}

		driverUpdates = append(driverUpdates, columnName+" = ?")
		driverArgs = append(driverArgs, targetName)

		return nil
	}

	imageFields := []struct {
		formKey    string
		columnName string
		targetName string
	}{
		{
			formKey:    "driving_license_front_side",
			columnName: "driving_license_front_side",
			targetName: fmt.Sprintf("%d_license_front_side.jpg", driverID),
		},
		{
			formKey:    "driving_license_back_side",
			columnName: "driving_license_back_side",
			targetName: fmt.Sprintf("%d_driver_license_back_side.jpg", driverID),
		},
		{
			formKey:    "front_side_of_the_identity_card",
			columnName: "front_side_of_the_identity_card",
			targetName: fmt.Sprintf("%d_driver_front_side.jpg", driverID),
		},
		{
			formKey:    "the_back_of_the_identity_card",
			columnName: "the_back_of_the_identity_card",
			targetName: fmt.Sprintf("%d_driver_back_side.png", driverID),
		},
	}

	for _, field := range imageFields {
		err = saveImage(
			field.formKey,
			field.columnName,
			field.targetName,
		)

		if err != nil {
			log.Println("Lỗi lưu ảnh:", err)
			w.WriteHeader(http.StatusBadRequest)
			json.NewEncoder(w).Encode(map[string]string{
				"error": err.Error(),
			})
			return
		}
	}

	if len(driverUpdates) > 0 {
		driverArgs = append(driverArgs, driverID)

		updateQuery := fmt.Sprintf(
			"UPDATE Driver SET %s WHERE driver_id = ?",
			strings.Join(driverUpdates, ", "),
		)

		_, err = tx.Exec(updateQuery, driverArgs...)
		if err != nil {
			log.Println("Lỗi cập nhật Driver:", err)
			w.WriteHeader(http.StatusInternalServerError)
			json.NewEncoder(w).Encode(map[string]string{
				"error": "Lỗi cập nhật thông tin tài xế",
			})
			return
		}
	}

	_, err = tx.Exec(
		"DELETE FROM ReasonReject WHERE driver_id = ?",
		driverID,
	)

	if err != nil {
		log.Println("Lỗi xóa ReasonReject:", err)
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(map[string]string{
			"error": "Lỗi cập nhật trạng thái hồ sơ",
		})
		return
	}

	err = tx.Commit()
	if err != nil {
		log.Println("Lỗi commit transaction:", err)
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(map[string]string{
			"error": "Lỗi hoàn tất đăng ký lại",
		})
		return
	}

	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]interface{}{
		"data": map[string]interface{}{
			"driver_id": driverID,
			"active":    0,
			"message":   "Cập nhật hồ sơ thành công. Vui lòng chờ quản trị viên phê duyệt lại.",
		},
	})
}

func getUserProfile(w http.ResponseWriter, r *http.Request) {
	type UserProfileResponse struct {
		ProfileID         int    `json:"profile_id"`
		UserName          string `json:"user_name"`
		FullName          string `json:"full_name"`
		PhoneNumber       string `json:"phone_number"`
		Address           string `json:"address"`
		Image             string `json:"image"`
		BankName          string `json:"bank_name"`
		BankAccountNumber string `json:"bank_account_number"`
		BankAccountName   string `json:"bank_account_name"`
		BankQRCode        string `json:"bank_qr_code"`

		DrivingLicenseFrontSide    string `json:"driving_license_front_side,omitempty"`
		DrivingLicenseBackSide     string `json:"driving_license_back_side,omitempty"`
		FrontSideOfTheIdentityCard string `json:"front_side_of_the_identity_card,omitempty"`
		TheBackOfTheIdentityCard   string `json:"the_back_of_the_identity_card,omitempty"`
	}

	w.Header().Set("Content-Type", "application/json")

	profileID, err := strconv.Atoi(mux.Vars(r)["id"])
	if err != nil || profileID <= 0 {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(map[string]string{
			"error": "profile_id không hợp lệ",
		})
		return
	}

	query := `
		SELECT p.profile_id, p.user_name, p.full_name, p.phone_number, p.address,
		       p.image, p.bank_name, p.bank_account_number, p.bank_account_name,
		       p.bank_qr_code, r.role_value
		FROM Profile p
		INNER JOIN Role r ON p.role_id = r.role_id
		WHERE p.profile_id = ?
	`

	var profile UserProfileResponse
	var fullName, phoneNumber, address, image sql.NullString
	var bankName, bankAccountNumber, bankAccountName, bankQRCode sql.NullString
	var roleValue string

	err = db.QueryRow(query, profileID).Scan(
		&profile.ProfileID,
		&profile.UserName,
		&fullName,
		&phoneNumber,
		&address,
		&image,
		&bankName,
		&bankAccountNumber,
		&bankAccountName,
		&bankQRCode,
		&roleValue,
	)

	if err != nil {
		if err == sql.ErrNoRows {
			w.WriteHeader(http.StatusNotFound)
			json.NewEncoder(w).Encode(map[string]string{
				"error": "Không tìm thấy người dùng",
			})
			return
		}

		log.Printf("Lỗi lấy thông tin người dùng: %v", err)
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(map[string]string{
			"error": "Lỗi hệ thống khi lấy thông tin người dùng",
		})
		return
	}

	baseImgURL := fmt.Sprintf("http://%s:8080/image/", getLocalIP())

	imageURL := func(filename sql.NullString) string {
		if !filename.Valid || filename.String == "" {
			return ""
		}
		return baseImgURL + filename.String
	}

	profile.FullName = parseNullString(fullName)
	profile.PhoneNumber = parseNullString(phoneNumber)
	profile.Address = parseNullString(address)
	profile.Image = imageURL(image)
	profile.BankName = parseNullString(bankName)
	profile.BankAccountNumber = parseNullString(bankAccountNumber)
	profile.BankAccountName = parseNullString(bankAccountName)
	profile.BankQRCode = imageURL(bankQRCode)

	if roleValue == "DRIVER" {
		var licenseFront, licenseBack, identityFront, identityBack sql.NullString

		err = db.QueryRow(`
			SELECT driving_license_front_side, driving_license_back_side,
			       front_side_of_the_identity_card, the_back_of_the_identity_card
			FROM Driver
			WHERE driver_id = ?`, profileID,
		).Scan(&licenseFront, &licenseBack, &identityFront, &identityBack)

		if err != nil && err != sql.ErrNoRows {
			log.Printf("Lỗi lấy thông tin giấy tờ tài xế: %v", err)
			w.WriteHeader(http.StatusInternalServerError)
			json.NewEncoder(w).Encode(map[string]string{
				"error": "Lỗi hệ thống khi lấy thông tin tài xế",
			})
			return
		}

		if err == nil {
			profile.DrivingLicenseFrontSide = imageURL(licenseFront)
			profile.DrivingLicenseBackSide = imageURL(licenseBack)
			profile.FrontSideOfTheIdentityCard = imageURL(identityFront)
			profile.TheBackOfTheIdentityCard = imageURL(identityBack)
		}
	}

	apiResponse := struct {
		Data UserProfileResponse `json:"data"`
	}{
		Data: profile,
	}

	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(apiResponse)
}

func updateUserProfile(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	if r.Method != http.MethodPost && r.Method != http.MethodPatch {
		w.WriteHeader(http.StatusMethodNotAllowed)
		json.NewEncoder(w).Encode(map[string]string{
			"error": "Phương thức không được hỗ trợ",
		})
		return
	}

	id, err := strconv.Atoi(mux.Vars(r)["id"])
	if err != nil || id <= 0 {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(map[string]string{
			"error": "profile_id không hợp lệ",
		})
		return
	}

	r.Body = http.MaxBytesReader(w, r.Body, 10<<20)

	err = r.ParseMultipartForm(10 << 20)
	if err != nil {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(map[string]string{
			"error": "Dữ liệu không hợp lệ hoặc file vượt quá dung lượng cho phép",
		})
		return
	}

	var exists int

	err = db.QueryRow(
		`SELECT 1 FROM Profile WHERE profile_id = ?`,
		id,
	).Scan(&exists)

	if err != nil {
		if err == sql.ErrNoRows {
			w.WriteHeader(http.StatusNotFound)
			json.NewEncoder(w).Encode(map[string]string{
				"error": "Không tìm thấy người dùng",
			})
			return
		}

		log.Printf("Lỗi lấy thông tin Profile: %v", err)
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(map[string]string{
			"error": "Lỗi hệ thống",
		})
		return
	}

	var setClauses []string
	var args []interface{}

	fullName := strings.TrimSpace(r.FormValue("full_name"))
	phoneNumber := strings.TrimSpace(r.FormValue("phone_number"))
	address := strings.TrimSpace(r.FormValue("address"))

	if fullName != "" {
		if len([]rune(fullName)) > 45 {
			w.WriteHeader(http.StatusBadRequest)
			json.NewEncoder(w).Encode(map[string]string{
				"error": "full_name tối đa 45 ký tự",
			})
			return
		}
		setClauses = append(setClauses, "full_name = ?")
		args = append(args, fullName)
	}

	if phoneNumber != "" {
		digits := strings.TrimPrefix(phoneNumber, "+")
		validPhone := len(digits) >= 9 && len(digits) <= 15
		for _, c := range digits {
			if c < '0' || c > '9' {
				validPhone = false
				break
			}
		}
		if !validPhone {
			w.WriteHeader(http.StatusBadRequest)
			json.NewEncoder(w).Encode(map[string]string{
				"error": "phone_number không hợp lệ",
			})
			return
		}
		setClauses = append(setClauses, "phone_number = ?")
		args = append(args, phoneNumber)
	}

	if address != "" {
		if len([]rune(address)) > 45 {
			w.WriteHeader(http.StatusBadRequest)
			json.NewEncoder(w).Encode(map[string]string{
				"error": "address tối đa 45 ký tự",
			})
			return
		}
		setClauses = append(setClauses, "address = ?")
		args = append(args, address)
	}

	var newImageName string
	var tempImagePath string

	uploadedFiles := r.MultipartForm.File["image"]

	if len(uploadedFiles) > 0 {
		header := uploadedFiles[0]

		file, err := header.Open()
		if err != nil {
			w.WriteHeader(http.StatusBadRequest)
			json.NewEncoder(w).Encode(map[string]string{
				"error": "Không thể đọc file ảnh",
			})
			return
		}
		defer file.Close()

		ext := strings.ToLower(filepath.Ext(header.Filename))

		allowedExts := map[string]bool{
			".jpg":  true,
			".jpeg": true,
			".png":  true,
			".webp": true,
		}

		if !allowedExts[ext] {
			w.WriteHeader(http.StatusBadRequest)
			json.NewEncoder(w).Encode(map[string]string{
				"error": "Chỉ hỗ trợ ảnh JPG, JPEG, PNG hoặc WEBP",
			})
			return
		}

		if err := os.MkdirAll("image", os.ModePerm); err != nil {
			log.Printf("Lỗi tạo thư mục image: %v", err)
			w.WriteHeader(http.StatusInternalServerError)
			json.NewEncoder(w).Encode(map[string]string{
				"error": "Không thể tạo thư mục lưu ảnh",
			})
			return
		}

		tempFile, err := os.CreateTemp("image", "avatar_tmp_*")
		if err != nil {
			log.Printf("Lỗi tạo file tạm: %v", err)
			w.WriteHeader(http.StatusInternalServerError)
			json.NewEncoder(w).Encode(map[string]string{
				"error": "Không thể lưu ảnh",
			})
			return
		}
		tempImagePath = tempFile.Name()

		defer func() {
			if tempImagePath != "" {
				os.Remove(tempImagePath)
			}
		}()

		_, copyErr := io.Copy(tempFile, file)
		closeErr := tempFile.Close()

		if copyErr != nil || closeErr != nil {
			log.Printf("Lỗi ghi ảnh: copy=%v close=%v", copyErr, closeErr)
			w.WriteHeader(http.StatusInternalServerError)
			json.NewEncoder(w).Encode(map[string]string{
				"error": "Không thể lưu ảnh",
			})
			return
		}

		newImageName = fmt.Sprintf("%d_image.jpg", id)
		setClauses = append(setClauses, "image = ?")
		args = append(args, newImageName)
	}

	if len(setClauses) == 0 {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(map[string]string{
			"error": "Không có trường nào để cập nhật",
		})
		return
	}

	args = append(args, id)

	updateQuery := fmt.Sprintf(
		"UPDATE Profile SET %s WHERE profile_id = ?",
		strings.Join(setClauses, ", "),
	)

	_, err = db.Exec(updateQuery, args...)
	if err != nil {
		log.Printf("Lỗi cập nhật Profile: %v", err)
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(map[string]string{
			"error": "Lỗi cập nhật thông tin người dùng",
		})
		return
	}

	if tempImagePath != "" {
		finalPath := filepath.Join("image", newImageName)

		if err := os.Rename(tempImagePath, finalPath); err != nil {
			log.Printf("Lỗi đổi tên ảnh đại diện: %v", err)
		} else {
			tempImagePath = ""
		}
	}
	getUserProfile(w, r)
}

type TopupRequestResponse struct {
	TransactionID    int     `json:"transaction_id"`
	DriverID         int     `json:"driver_id"`
	DriverName       string  `json:"driver_name"`
	Balance          float64 `json:"balance"`
	ImageTransaction string  `json:"image_transaction"`
	Active           int     `json:"active"`
	Status           string  `json:"status"`
	Time             string  `json:"time"`
	RejectReason     string  `json:"reject_reason"`
}

type topupRowScanner interface {
	Scan(dest ...interface{}) error
}

const topupSelectQuery = "SELECT t.transaction_id, t.driver_id, p.full_name, t.balance, " +
	"t.image_transaction, t.active, t.`time`, t.reject_reason " +
	"FROM DiverTransaction t " +
	"INNER JOIN Profile p ON p.profile_id = t.driver_id "

func topupError(w http.ResponseWriter, status int, msg string) {
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(map[string]string{"error": msg})
}

func topupStatus(active int, rejectReason string) string {
	if active == 1 {
		return "APPROVED"
	}
	if rejectReason != "" {
		return "REJECTED"
	}
	return "PENDING"
}

func topupStatusClause(status string) (string, bool) {
	switch strings.ToLower(strings.TrimSpace(status)) {
	case "":
		return "", true
	case "pending":
		return "t.active = 0 AND (t.reject_reason IS NULL OR t.reject_reason = '')", true
	case "approved":
		return "t.active = 1", true
	case "rejected":
		return "t.active = 0 AND t.reject_reason <> ''", true
	}
	return "", false
}

func scanTopupRequest(sc topupRowScanner) (TopupRequestResponse, error) {
	var t TopupRequestResponse
	var driverName, image, rejectReason sql.NullString
	var createdAt time.Time

	err := sc.Scan(
		&t.TransactionID, &t.DriverID, &driverName, &t.Balance,
		&image, &t.Active, &createdAt, &rejectReason,
	)
	if err != nil {
		return t, err
	}

	t.DriverName = parseNullString(driverName)
	if img := parseNullString(image); img != "" {
		t.ImageTransaction = fmt.Sprintf("http://%s:8080/image/%s", getLocalIP(), img)
	}
	t.Time = createdAt.Format("2006-01-02 15:04:05")
	t.RejectReason = parseNullString(rejectReason)
	t.Status = topupStatus(t.Active, t.RejectReason)
	return t, nil
}

func loadTopupRequest(transactionID int) (TopupRequestResponse, error) {
	return scanTopupRequest(
		db.QueryRow(topupSelectQuery+"WHERE t.transaction_id = ?", transactionID),
	)
}

func saveTopupTempImage(src io.Reader, filename string) (string, int, string) {
	ext := strings.ToLower(filepath.Ext(filename))
	if ext != ".jpg" && ext != ".jpeg" && ext != ".png" && ext != ".webp" {
		return "", http.StatusBadRequest, "Chỉ hỗ trợ ảnh JPG, JPEG, PNG hoặc WEBP"
	}

	if err := os.MkdirAll("image", os.ModePerm); err != nil {
		log.Printf("Lỗi tạo thư mục image: %v", err)
		return "", http.StatusInternalServerError, "Không thể tạo thư mục lưu ảnh"
	}

	tmp, err := os.CreateTemp("image", "transaction_tmp_*")
	if err != nil {
		log.Printf("Lỗi tạo file tạm: %v", err)
		return "", http.StatusInternalServerError, "Không thể lưu ảnh"
	}

	_, copyErr := io.Copy(tmp, src)
	closeErr := tmp.Close()
	if copyErr != nil || closeErr != nil {
		log.Printf("Lỗi ghi ảnh: copy=%v close=%v", copyErr, closeErr)
		os.Remove(tmp.Name())
		return "", http.StatusInternalServerError, "Không thể lưu ảnh"
	}

	return tmp.Name(), 0, ""
}

func createTopupRequest(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	r.Body = http.MaxBytesReader(w, r.Body, 10<<20)
	if err := r.ParseMultipartForm(10 << 20); err != nil {
		topupError(w, http.StatusBadRequest, "Dữ liệu không hợp lệ hoặc file vượt quá dung lượng cho phép")
		return
	}

	driverID, err := strconv.Atoi(strings.TrimSpace(r.FormValue("driver_id")))
	if err != nil || driverID <= 0 {
		topupError(w, http.StatusBadRequest, "driver_id không hợp lệ")
		return
	}

	balance64, err := strconv.ParseInt(strings.TrimSpace(r.FormValue("balance")), 10, 32)
	if err != nil || balance64 <= 0 {
		topupError(w, http.StatusBadRequest, "balance phải là số nguyên dương")
		return
	}
	balance := int(balance64)

	imageFile, imageHeader, err := r.FormFile("image_transaction")
	if err != nil {
		topupError(w, http.StatusBadRequest, "Vui lòng gửi ảnh chuyển khoản (image_transaction)")
		return
	}
	defer imageFile.Close()

	var driverActive int
	err = db.QueryRow("SELECT active FROM Driver WHERE driver_id = ?", driverID).Scan(&driverActive)
	if err == sql.ErrNoRows {
		topupError(w, http.StatusNotFound, "Không tìm thấy tài xế")
		return
	}
	if err != nil {
		log.Printf("Lỗi kiểm tra tài xế: %v", err)
		topupError(w, http.StatusInternalServerError, "Lỗi hệ thống")
		return
	}
	if driverActive != 1 {
		topupError(w, http.StatusForbidden, "Tài xế chưa được phê duyệt")
		return
	}

	tempPath, status, msg := saveTopupTempImage(imageFile, imageHeader.Filename)
	if status != 0 {
		topupError(w, status, msg)
		return
	}
	defer func() {
		if tempPath != "" {
			os.Remove(tempPath)
		}
	}()

	tx, err := db.Begin()
	if err != nil {
		log.Printf("Lỗi Begin Transaction: %v", err)
		topupError(w, http.StatusInternalServerError, "Không thể khởi tạo tiến trình xử lý dữ liệu")
		return
	}
	defer tx.Rollback()

	res, err := tx.Exec(
		"INSERT INTO DiverTransaction (balance, image_transaction, active, reject_reason, driver_id, `time`) "+
			"VALUES (?, '', 0, '', ?, NOW())",
		balance, driverID,
	)
	if err != nil {
		log.Printf("Lỗi tạo yêu cầu nạp tiền: %v", err)
		topupError(w, http.StatusInternalServerError, "Lỗi hệ thống khi tạo yêu cầu nạp tiền")
		return
	}

	transactionID64, err := res.LastInsertId()
	if err != nil {
		log.Printf("Lỗi lấy transaction_id: %v", err)
		topupError(w, http.StatusInternalServerError, "Lỗi hệ thống khi tạo yêu cầu nạp tiền")
		return
	}
	transactionID := int(transactionID64)

	imageName := fmt.Sprintf("%d_transaction_%d.jpg", driverID, transactionID)

	_, err = tx.Exec(
		"UPDATE DiverTransaction SET image_transaction = ? WHERE transaction_id = ?",
		imageName, transactionID,
	)
	if err != nil {
		log.Printf("Lỗi lưu tên ảnh giao dịch: %v", err)
		topupError(w, http.StatusInternalServerError, "Lỗi hệ thống khi lưu ảnh giao dịch")
		return
	}

	finalPath := filepath.Join("image", imageName)
	if err := os.Rename(tempPath, finalPath); err != nil {
		log.Printf("Lỗi đổi tên ảnh giao dịch: %v", err)
		topupError(w, http.StatusInternalServerError, "Không thể lưu ảnh giao dịch")
		return
	}
	tempPath = ""

	if err := tx.Commit(); err != nil {
		os.Remove(finalPath)
		log.Printf("Lỗi Commit Transaction: %v", err)
		topupError(w, http.StatusInternalServerError, "Lỗi hệ thống khi xác nhận dữ liệu")
		return
	}

	created, err := loadTopupRequest(transactionID)
	if err != nil {
		log.Printf("Lỗi đọc lại yêu cầu nạp tiền: %v", err)
		topupError(w, http.StatusInternalServerError, "Đã tạo yêu cầu nhưng không thể đọc lại dữ liệu")
		return
	}

	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(struct {
		Data TopupRequestResponse `json:"data"`
	}{Data: created})
}

func reviewTopupRequest(w http.ResponseWriter, r *http.Request) {
	type ReviewTopupRequest struct {
		Status bool   `json:"status"`
		Reason string `json:"reason"`
	}

	w.Header().Set("Content-Type", "application/json")

	transactionID, err := strconv.Atoi(mux.Vars(r)["id"])
	if err != nil || transactionID <= 0 {
		topupError(w, http.StatusBadRequest, "transaction_id không hợp lệ")
		return
	}

	var req ReviewTopupRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		topupError(w, http.StatusBadRequest, "Dữ liệu JSON không hợp lệ")
		return
	}
	req.Reason = strings.TrimSpace(req.Reason)

	if !req.Status {
		if req.Reason == "" {
			topupError(w, http.StatusBadRequest, "Vui lòng cung cấp lý do từ chối (reason)")
			return
		}
		if len([]rune(req.Reason)) > 255 {
			topupError(w, http.StatusBadRequest, "reason tối đa 255 ký tự")
			return
		}
	}

	tx, err := db.Begin()
	if err != nil {
		log.Printf("Lỗi Begin Transaction: %v", err)
		topupError(w, http.StatusInternalServerError, "Không thể khởi tạo tiến trình xử lý dữ liệu")
		return
	}
	defer tx.Rollback()

	var driverID, active int
	var balance float64
	var rejectReason sql.NullString

	err = tx.QueryRow(
		"SELECT driver_id, balance, active, reject_reason FROM DiverTransaction WHERE transaction_id = ? FOR UPDATE",
		transactionID,
	).Scan(&driverID, &balance, &active, &rejectReason)
	if err == sql.ErrNoRows {
		topupError(w, http.StatusNotFound, "Không tìm thấy yêu cầu nạp tiền")
		return
	}
	if err != nil {
		log.Printf("Lỗi lấy yêu cầu nạp tiền: %v", err)
		topupError(w, http.StatusInternalServerError, "Lỗi hệ thống")
		return
	}

	if topupStatus(active, parseNullString(rejectReason)) != "PENDING" {
		topupError(w, http.StatusConflict, "Yêu cầu nạp tiền này đã được xử lý")
		return
	}

	if req.Status {
		moneyAdd := int64(balance + 0.5)

		_, err = tx.Exec("UPDATE DiverTransaction SET active = 1 WHERE transaction_id = ?", transactionID)
		if err != nil {
			log.Printf("Lỗi duyệt yêu cầu nạp tiền: %v", err)
			topupError(w, http.StatusInternalServerError, "Lỗi hệ thống khi duyệt yêu cầu")
			return
		}

		_, err = tx.Exec(
			"INSERT INTO DriverWallet (driver_id, money) VALUES (?, ?) "+
				"ON DUPLICATE KEY UPDATE money = IFNULL(money, 0) + ?",
			driverID, moneyAdd, moneyAdd,
		)
		if err != nil {
			log.Printf("Lỗi cộng tiền vào ví: %v", err)
			topupError(w, http.StatusInternalServerError, "Lỗi hệ thống khi cộng tiền vào ví")
			return
		}
	} else {
		_, err = tx.Exec("UPDATE DiverTransaction SET reject_reason = ? WHERE transaction_id = ?", req.Reason, transactionID)
		if err != nil {
			log.Printf("Lỗi từ chối yêu cầu nạp tiền: %v", err)
			topupError(w, http.StatusInternalServerError, "Lỗi hệ thống khi từ chối yêu cầu")
			return
		}
	}

	if err := tx.Commit(); err != nil {
		log.Printf("Lỗi Commit Transaction: %v", err)
		topupError(w, http.StatusInternalServerError, "Lỗi hệ thống khi xác nhận dữ liệu")
		return
	}

	updated, err := loadTopupRequest(transactionID)
	if err != nil {
		log.Printf("Lỗi đọc lại yêu cầu nạp tiền: %v", err)
		topupError(w, http.StatusInternalServerError, "Đã xử lý nhưng không thể đọc lại dữ liệu")
		return
	}

	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(struct {
		Data TopupRequestResponse `json:"data"`
	}{Data: updated})
}

func getAllTopupRequests(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	clause, ok := topupStatusClause(r.URL.Query().Get("status"))
	if !ok {
		topupError(w, http.StatusBadRequest, "status chỉ nhận pending, approved hoặc rejected")
		return
	}

	query := topupSelectQuery
	if clause != "" {
		query += "WHERE " + clause + " "
	}
	query += "ORDER BY t.`time` DESC, t.transaction_id DESC"

	rows, err := db.Query(query)
	if err != nil {
		log.Printf("Lỗi lấy danh sách nạp tiền: %v", err)
		topupError(w, http.StatusInternalServerError, "Lỗi hệ thống khi lấy danh sách nạp tiền")
		return
	}
	defer rows.Close()

	list := []TopupRequestResponse{}
	for rows.Next() {
		t, err := scanTopupRequest(rows)
		if err != nil {
			log.Printf("Lỗi đọc dòng nạp tiền: %v", err)
			topupError(w, http.StatusInternalServerError, "Đã xảy ra lỗi server")
			return
		}
		list = append(list, t)
	}
	if err := rows.Err(); err != nil {
		log.Printf("Lỗi duyệt danh sách nạp tiền: %v", err)
		topupError(w, http.StatusInternalServerError, "Đã xảy ra lỗi server")
		return
	}

	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(list)
}

func getDriverWallet(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	driverID, err := strconv.Atoi(mux.Vars(r)["id"])
	if err != nil || driverID <= 0 {
		topupError(w, http.StatusBadRequest, "driver_id khong hop le")
		return
	}

	var balance int64
	err = db.QueryRowContext(r.Context(), `
		SELECT COALESCE(w.money, 0)
		FROM Driver d
		LEFT JOIN DriverWallet w ON w.driver_id = d.driver_id
		WHERE d.driver_id = ?
	`, driverID).Scan(&balance)
	if err == sql.ErrNoRows {
		topupError(w, http.StatusNotFound, "Khong tim thay tai xe")
		return
	}
	if err != nil {
		log.Printf("Error loading driver %d wallet: %v", driverID, err)
		topupError(w, http.StatusInternalServerError, "Khong the lay so du vi")
		return
	}

	json.NewEncoder(w).Encode(map[string]interface{}{
		"data": map[string]interface{}{
			"driver_id": driverID,
			"balance":   balance,
		},
	})
}

func getDriverTopupRequests(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	driverID, err := strconv.Atoi(mux.Vars(r)["id"])
	if err != nil || driverID <= 0 {
		topupError(w, http.StatusBadRequest, "driver_id không hợp lệ")
		return
	}

	clause, ok := topupStatusClause(r.URL.Query().Get("status"))
	if !ok {
		topupError(w, http.StatusBadRequest, "status chỉ nhận pending, approved hoặc rejected")
		return
	}

	query := topupSelectQuery + "WHERE t.driver_id = ? "
	if clause != "" {
		query += "AND " + clause + " "
	}
	query += "ORDER BY t.`time` DESC, t.transaction_id DESC"

	rows, err := db.Query(query, driverID)
	if err != nil {
		log.Printf("Lỗi lấy danh sách nạp tiền của tài xế: %v", err)
		topupError(w, http.StatusInternalServerError, "Lỗi hệ thống khi lấy danh sách nạp tiền")
		return
	}
	defer rows.Close()

	list := []TopupRequestResponse{}
	for rows.Next() {
		t, err := scanTopupRequest(rows)
		if err != nil {
			log.Printf("Lỗi đọc dòng nạp tiền: %v", err)
			topupError(w, http.StatusInternalServerError, "Đã xảy ra lỗi server")
			return
		}
		list = append(list, t)
	}
	if err := rows.Err(); err != nil {
		log.Printf("Lỗi duyệt danh sách nạp tiền: %v", err)
		topupError(w, http.StatusInternalServerError, "Đã xảy ra lỗi server")
		return
	}

	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(list)
}

func getTopupRequestDetail(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	transactionID, err := strconv.Atoi(mux.Vars(r)["id"])
	if err != nil || transactionID <= 0 {
		topupError(w, http.StatusBadRequest, "transaction_id không hợp lệ")
		return
	}

	detail, err := loadTopupRequest(transactionID)
	if err == sql.ErrNoRows {
		topupError(w, http.StatusNotFound, "Không tìm thấy yêu cầu nạp tiền")
		return
	}
	if err != nil {
		log.Printf("Lỗi lấy chi tiết nạp tiền: %v", err)
		topupError(w, http.StatusInternalServerError, "Lỗi hệ thống khi lấy chi tiết yêu cầu")
		return
	}

	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(struct {
		Data TopupRequestResponse `json:"data"`
	}{Data: detail})
}

func updateTopupRequest(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	transactionID, err := strconv.Atoi(mux.Vars(r)["id"])
	if err != nil || transactionID <= 0 {
		topupError(w, http.StatusBadRequest, "transaction_id không hợp lệ")
		return
	}

	r.Body = http.MaxBytesReader(w, r.Body, 10<<20)
	if err := r.ParseMultipartForm(10 << 20); err != nil {
		topupError(w, http.StatusBadRequest, "Dữ liệu không hợp lệ hoặc file vượt quá dung lượng cho phép")
		return
	}

	driverID, err := strconv.Atoi(strings.TrimSpace(r.FormValue("driver_id")))
	if err != nil || driverID <= 0 {
		topupError(w, http.StatusBadRequest, "driver_id không hợp lệ")
		return
	}

	var setClauses []string
	var args []interface{}

	balanceStr := strings.TrimSpace(r.FormValue("balance"))
	if balanceStr != "" {
		balance64, err := strconv.ParseInt(balanceStr, 10, 32)
		if err != nil || balance64 <= 0 {
			topupError(w, http.StatusBadRequest, "balance phải là số nguyên dương")
			return
		}
		setClauses = append(setClauses, "balance = ?")
		args = append(args, int(balance64))
	}

	imageFile, imageHeader, imgErr := r.FormFile("image_transaction")
	hasImage := imgErr == nil
	if hasImage {
		defer imageFile.Close()
	} else if imgErr != http.ErrMissingFile {
		topupError(w, http.StatusBadRequest, "Không thể đọc file ảnh")
		return
	}

	if len(setClauses) == 0 && !hasImage {
		topupError(w, http.StatusBadRequest, "Không có trường nào để cập nhật (balance, image_transaction)")
		return
	}

	tx, err := db.Begin()
	if err != nil {
		log.Printf("Lỗi Begin Transaction: %v", err)
		topupError(w, http.StatusInternalServerError, "Không thể khởi tạo tiến trình xử lý dữ liệu")
		return
	}
	defer tx.Rollback()

	var ownerID, active int
	err = tx.QueryRow(
		"SELECT driver_id, active FROM DiverTransaction WHERE transaction_id = ? FOR UPDATE",
		transactionID,
	).Scan(&ownerID, &active)
	if err == sql.ErrNoRows {
		topupError(w, http.StatusNotFound, "Không tìm thấy yêu cầu nạp tiền")
		return
	}
	if err != nil {
		log.Printf("Lỗi lấy yêu cầu nạp tiền: %v", err)
		topupError(w, http.StatusInternalServerError, "Lỗi hệ thống")
		return
	}
	if ownerID != driverID {
		topupError(w, http.StatusForbidden, "Bạn không có quyền chỉnh sửa yêu cầu này")
		return
	}
	if active == 1 {
		topupError(w, http.StatusConflict, "Yêu cầu đã được duyệt, không thể chỉnh sửa")
		return
	}

	var tempPath, finalPath string
	if hasImage {
		var status int
		var msg string
		tempPath, status, msg = saveTopupTempImage(imageFile, imageHeader.Filename)
		if status != 0 {
			topupError(w, status, msg)
			return
		}
		defer func() {
			if tempPath != "" {
				os.Remove(tempPath)
			}
		}()

		imageName := fmt.Sprintf("%d_transaction_%d.jpg", driverID, transactionID)
		finalPath = filepath.Join("image", imageName)
		setClauses = append(setClauses, "image_transaction = ?")
		args = append(args, imageName)
	}

	setClauses = append(setClauses, "reject_reason = ''")
	args = append(args, transactionID)

	updateQuery := fmt.Sprintf(
		"UPDATE DiverTransaction SET %s WHERE transaction_id = ?",
		strings.Join(setClauses, ", "),
	)
	if _, err = tx.Exec(updateQuery, args...); err != nil {
		log.Printf("Lỗi cập nhật yêu cầu nạp tiền: %v", err)
		topupError(w, http.StatusInternalServerError, "Lỗi hệ thống khi cập nhật yêu cầu nạp tiền")
		return
	}

	if err := tx.Commit(); err != nil {
		log.Printf("Lỗi Commit Transaction: %v", err)
		topupError(w, http.StatusInternalServerError, "Lỗi hệ thống khi xác nhận dữ liệu")
		return
	}

	if tempPath != "" {
		if err := os.Rename(tempPath, finalPath); err != nil {
			log.Printf("Lỗi đổi tên ảnh giao dịch: %v", err)
		} else {
			tempPath = ""
		}
	}

	updated, err := loadTopupRequest(transactionID)
	if err != nil {
		log.Printf("Lỗi đọc lại yêu cầu nạp tiền: %v", err)
		topupError(w, http.StatusInternalServerError, "Đã cập nhật nhưng không thể đọc lại dữ liệu")
		return
	}

	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(struct {
		Data TopupRequestResponse `json:"data"`
	}{Data: updated})
}

func getAdminBankInfo(w http.ResponseWriter, r *http.Request) {
	var adminID int

	err := db.QueryRow(`
		SELECT p.profile_id
		FROM Profile p
		INNER JOIN Role ro ON p.role_id = ro.role_id
		WHERE ro.role_value = 'ADMIN'
		ORDER BY p.profile_id
		LIMIT 1
	`).Scan(&adminID)

	if err != nil {
		w.Header().Set("Content-Type", "application/json")
		if err == sql.ErrNoRows {
			topupError(w, http.StatusNotFound, "Không tìm thấy tài khoản admin")
			return
		}
		log.Printf("Lỗi tìm tài khoản admin: %v", err)
		topupError(w, http.StatusInternalServerError, "Lỗi hệ thống khi lấy thông tin ngân hàng")
		return
	}

	r = mux.SetURLVars(r, map[string]string{"id": strconv.Itoa(adminID)})
	getBankInfo(w, r)
}

// ===== Trip booking, driver dispatch and realtime tracking =====
const (
	tripStatusPendingV2   = 1
	tripStatusAcceptedV2  = 2
	tripStatusGoingV2     = 3
	tripStatusCompletedV2 = 4
	tripStatusCancelV2    = 5
)

type tripSocketClientV2 struct {
	conn    *websocket.Conn
	writeMu sync.Mutex
}

func (c *tripSocketClientV2) writeJSON(v interface{}) error {
	c.writeMu.Lock()
	defer c.writeMu.Unlock()
	_ = c.conn.SetWriteDeadline(time.Now().Add(5 * time.Second))
	return c.conn.WriteJSON(v)
}

var customerTripHubV2 = struct {
	sync.Mutex
	clients map[int]map[*tripSocketClientV2]struct{}
}{clients: make(map[int]map[*tripSocketClientV2]struct{})}

var driverTripHubV2 = struct {
	sync.Mutex
	clients map[int]map[*tripSocketClientV2]struct{}
}{clients: make(map[int]map[*tripSocketClientV2]struct{})}

func addCustomerTripClientV2(tripID int, client *tripSocketClientV2) {
	customerTripHubV2.Lock()
	defer customerTripHubV2.Unlock()
	if customerTripHubV2.clients[tripID] == nil {
		customerTripHubV2.clients[tripID] = make(map[*tripSocketClientV2]struct{})
	}
	customerTripHubV2.clients[tripID][client] = struct{}{}
}

func removeCustomerTripClientV2(tripID int, client *tripSocketClientV2) {
	customerTripHubV2.Lock()
	defer customerTripHubV2.Unlock()
	delete(customerTripHubV2.clients[tripID], client)
	if len(customerTripHubV2.clients[tripID]) == 0 {
		delete(customerTripHubV2.clients, tripID)
	}
}

func addDriverTripClientV2(driverID int, client *tripSocketClientV2) {
	driverTripHubV2.Lock()
	defer driverTripHubV2.Unlock()
	if driverTripHubV2.clients[driverID] == nil {
		driverTripHubV2.clients[driverID] = make(map[*tripSocketClientV2]struct{})
	}
	driverTripHubV2.clients[driverID][client] = struct{}{}
}

func removeDriverTripClientV2(driverID int, client *tripSocketClientV2) {
	driverTripHubV2.Lock()
	defer driverTripHubV2.Unlock()
	delete(driverTripHubV2.clients[driverID], client)
	if len(driverTripHubV2.clients[driverID]) == 0 {
		delete(driverTripHubV2.clients, driverID)
	}
}

func isDriverConnectedV2(driverID int) bool {
	driverTripHubV2.Lock()
	defer driverTripHubV2.Unlock()
	return len(driverTripHubV2.clients[driverID]) > 0
}

func sendDriverMessageV2(driverID int, message interface{}) bool {
	driverTripHubV2.Lock()
	clients := make([]*tripSocketClientV2, 0, len(driverTripHubV2.clients[driverID]))
	for client := range driverTripHubV2.clients[driverID] {
		clients = append(clients, client)
	}
	driverTripHubV2.Unlock()

	sent := false
	for _, client := range clients {
		if err := client.writeJSON(message); err != nil {
			log.Printf("WebSocket driver %d lỗi: %v", driverID, err)
			removeDriverTripClientV2(driverID, client)
			_ = client.conn.Close()
			continue
		}
		sent = true
	}
	return sent
}

func broadcastAllDriversV2(message interface{}) {
	driverTripHubV2.Lock()
	var clients []*tripSocketClientV2
	for _, group := range driverTripHubV2.clients {
		for client := range group {
			clients = append(clients, client)
		}
	}
	driverTripHubV2.Unlock()

	for _, client := range clients {
		if err := client.writeJSON(message); err != nil {
			_ = client.conn.Close()
		}
	}
}

func broadcastCustomerTripV2(tripID int, message interface{}) {
	customerTripHubV2.Lock()
	clients := make([]*tripSocketClientV2, 0, len(customerTripHubV2.clients[tripID]))
	for client := range customerTripHubV2.clients[tripID] {
		clients = append(clients, client)
	}
	customerTripHubV2.Unlock()

	for _, client := range clients {
		if err := client.writeJSON(message); err != nil {
			log.Printf("WebSocket customer trip %d lỗi: %v", tripID, err)
			removeCustomerTripClientV2(tripID, client)
			_ = client.conn.Close()
		}
	}
}

func tripJSONErrorV2(w http.ResponseWriter, statusCode int, message string) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(statusCode)
	_ = json.NewEncoder(w).Encode(map[string]string{"error": message})
}

func validCoordinateV2(latitude, longitude float64) bool {
	return !math.IsNaN(latitude) && !math.IsInf(latitude, 0) &&
		!math.IsNaN(longitude) && !math.IsInf(longitude, 0) &&
		latitude >= -90 && latitude <= 90 && longitude >= -180 && longitude <= 180
}

func tripHistoryOwnerColumn(role string) (string, bool) {
	switch strings.ToUpper(strings.TrimSpace(role)) {
	case "CUSTOMER":
		return "t.customer_id", true
	case "DRIVER":
		return "t.driver_id", true
	default:
		return "", false
	}
}

func parseTripHistoryParams(r *http.Request) (int, int, int, error) {
	profileID, err := strconv.Atoi(strings.TrimSpace(r.URL.Query().Get("profile_id")))
	if err != nil || profileID <= 0 {
		return 0, 0, 0, fmt.Errorf("profile_id không hợp lệ")
	}

	limit := 20
	if value := strings.TrimSpace(r.URL.Query().Get("limit")); value != "" {
		limit, err = strconv.Atoi(value)
		if err != nil || limit < 1 || limit > 100 {
			return 0, 0, 0, fmt.Errorf("limit phải từ 1 đến 100")
		}
	}

	offset := 0
	if value := strings.TrimSpace(r.URL.Query().Get("offset")); value != "" {
		offset, err = strconv.Atoi(value)
		if err != nil || offset < 0 {
			return 0, 0, 0, fmt.Errorf("offset phải từ 0 trở lên")
		}
	}
	return profileID, limit, offset, nil
}

func getTripHistoryByProfile(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")

	profileID, limit, offset, err := parseTripHistoryParams(r)
	if err != nil {
		tripJSONErrorV2(w, http.StatusBadRequest, err.Error())
		return
	}

	var role string
	err = db.QueryRowContext(r.Context(), `
		SELECT r.role_value
		FROM Profile p
		JOIN Role r ON r.role_id = p.role_id
		WHERE p.profile_id = ?
	`, profileID).Scan(&role)
	if err == sql.ErrNoRows {
		tripJSONErrorV2(w, http.StatusNotFound, "Không tìm thấy profile")
		return
	}
	if err != nil {
		tripJSONErrorV2(w, http.StatusInternalServerError, "Không thể kiểm tra profile")
		return
	}

	ownerColumn, supported := tripHistoryOwnerColumn(role)
	if !supported {
		tripJSONErrorV2(w, http.StatusForbidden, "Role này không có lịch sử chuyến đi")
		return
	}

	query := fmt.Sprintf(`
		SELECT t.trip_id, t.trip_distance, t.trip_price,
		       t.customer_id, t.driver_id, t.trip_status_id, ts.status,
		       t.trip_latitude, t.trip_longitude,
		       t.destination_latitude, t.destination_longitude,
		       COALESCE(NULLIF(cp.full_name, ''), cp.user_name),
		       COALESCE(NULLIF(dp.full_name, ''), dp.user_name),
		       rt.vote, rt.comment
		FROM Trip t
		JOIN TripStatus ts ON ts.trip_status_id = t.trip_status_id
		JOIN Profile cp ON cp.profile_id = t.customer_id
		LEFT JOIN Profile dp ON dp.profile_id = t.driver_id
		LEFT JOIN ReviewTrip rt ON rt.reviewId = (
			SELECT MAX(rt2.reviewId) FROM ReviewTrip rt2 WHERE rt2.trip_id = t.trip_id
		)
		WHERE %s = ? AND t.trip_status_id IN (?, ?)
		ORDER BY t.trip_id DESC
		LIMIT ? OFFSET ?
	`, ownerColumn)
	rows, err := db.QueryContext(
		r.Context(), query,
		profileID, tripStatusCompletedV2, tripStatusCancelV2, limit+1, offset,
	)
	if err != nil {
		tripJSONErrorV2(w, http.StatusInternalServerError, "Không thể lấy lịch sử chuyến đi")
		return
	}
	defer rows.Close()

	history := make([]map[string]interface{}, 0, limit)
	for rows.Next() {
		var tripID, customerID, statusID int
		var distance, reviewVote sql.NullInt64
		var price sql.NullFloat64
		var driverID sql.NullInt64
		var status, customerName, driverName, reviewComment sql.NullString
		var pickupLat, pickupLng, destinationLat, destinationLng float64

		if err := rows.Scan(
			&tripID, &distance, &price,
			&customerID, &driverID, &statusID, &status,
			&pickupLat, &pickupLng, &destinationLat, &destinationLng,
			&customerName, &driverName, &reviewVote, &reviewComment,
		); err != nil {
			tripJSONErrorV2(w, http.StatusInternalServerError, "Không thể đọc lịch sử chuyến đi")
			return
		}

		item := map[string]interface{}{
			"trip_id":               tripID,
			"trip_distance":         nil,
			"trip_price":            nil,
			"customer_id":           customerID,
			"customer_name":         customerName.String,
			"driver_id":             nil,
			"driver_name":           nil,
			"trip_status_id":        statusID,
			"status_text":           status.String,
			"trip_latitude":         pickupLat,
			"trip_longitude":        pickupLng,
			"destination_latitude":  destinationLat,
			"destination_longitude": destinationLng,
			"review_vote":           nil,
			"review_comment":        nil,
		}
		if distance.Valid {
			item["trip_distance"] = distance.Int64
		}
		if price.Valid {
			item["trip_price"] = price.Float64
		}
		if driverID.Valid {
			item["driver_id"] = driverID.Int64
		}
		if driverName.Valid {
			item["driver_name"] = driverName.String
		}
		if reviewVote.Valid {
			item["review_vote"] = reviewVote.Int64
		}
		if reviewComment.Valid {
			item["review_comment"] = reviewComment.String
		}
		history = append(history, item)
	}
	if err := rows.Err(); err != nil {
		tripJSONErrorV2(w, http.StatusInternalServerError, "Không thể đọc lịch sử chuyến đi")
		return
	}

	hasMore := len(history) > limit
	if hasMore {
		history = history[:limit]
	}
	_ = json.NewEncoder(w).Encode(map[string]interface{}{
		"profile_id": profileID,
		"role":       strings.ToUpper(strings.TrimSpace(role)),
		"data":       history,
		"limit":      limit,
		"offset":     offset,
		"has_more":   hasMore,
	})
}

func getPriceConfig(db *sql.DB) http.HandlerFunc {
	type PriceConfigResponse struct {
		From       float64 `json:"from"`
		To         float64 `json:"to"`
		PricePerKm float64 `json:"price_per_km"`
	}
	return func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")

		rows, err := db.Query(`
            SELECT 
                ` + "`from`" + `,
                ` + "`to`" + `,
                price_per_km
            FROM PriceConfig
            ORDER BY ` + "`from`" + ` ASC
        `)

		if err != nil {
			http.Error(w, "Failed to get price config", http.StatusInternalServerError)
			return
		}
		defer rows.Close()

		configs := make([]PriceConfigResponse, 0)

		for rows.Next() {
			var config PriceConfigResponse

			err := rows.Scan(
				&config.From,
				&config.To,
				&config.PricePerKm,
			)

			if err != nil {
				http.Error(w, "Failed to read price config", http.StatusInternalServerError)
				return
			}

			configs = append(configs, config)
		}

		if err := rows.Err(); err != nil {
			http.Error(w, "Failed to read price config", http.StatusInternalServerError)
			return
		}

		json.NewEncoder(w).Encode(map[string]interface{}{
			"success": true,
			"data":    configs,
		})
	}
}

func getActiveDriverTripV2(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	driverID, err := strconv.Atoi(r.URL.Query().Get("driver_id"))
	if err != nil || driverID <= 0 {
		tripJSONErrorV2(w, http.StatusBadRequest, "driver_id không hợp lệ")
		return
	}

	var tripID, customerID, tripDistance, tripStatusID int
	var tripPrice, tripLatitude, tripLongitude, destinationLatitude, destinationLongitude float64
	var statusText sql.NullString
	err = db.QueryRowContext(r.Context(), `
		SELECT t.trip_id, t.customer_id, t.trip_distance, t.trip_price,
		       t.trip_latitude, t.trip_longitude,
		       t.destination_latitude, t.destination_longitude,
		       t.trip_status_id, ts.status
		FROM Trip t
		LEFT JOIN TripStatus ts ON ts.trip_status_id = t.trip_status_id
		WHERE t.driver_id = ? AND t.trip_status_id IN (?, ?)
		ORDER BY t.trip_id DESC
		LIMIT 1
	`, driverID, tripStatusAcceptedV2, tripStatusGoingV2).Scan(
		&tripID, &customerID, &tripDistance, &tripPrice,
		&tripLatitude, &tripLongitude, &destinationLatitude, &destinationLongitude,
		&tripStatusID, &statusText,
	)
	if err == sql.ErrNoRows {
		_ = json.NewEncoder(w).Encode(map[string]interface{}{"data": nil})
		return
	}
	if err != nil {
		log.Printf("Lỗi lấy chuyến đang hoạt động của driver %d: %v", driverID, err)
		tripJSONErrorV2(w, http.StatusInternalServerError, "Không thể lấy chuyến đang hoạt động")
		return
	}

	_ = json.NewEncoder(w).Encode(map[string]interface{}{
		"data": map[string]interface{}{
			"trip_id": tripID, "customer_id": customerID, "driver_id": driverID,
			"trip_distance": tripDistance, "trip_price": tripPrice,
			"trip_latitude": tripLatitude, "trip_longitude": tripLongitude,
			"destination_latitude":  destinationLatitude,
			"destination_longitude": destinationLongitude,
			"trip_status_id":        tripStatusID, "status_text": parseNullString(statusText),
		},
	})
}

func getActiveCustomerTripV2(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")

	customerID, err := strconv.Atoi(r.URL.Query().Get("customer_id"))
	if err != nil || customerID <= 0 {
		tripJSONErrorV2(w, http.StatusBadRequest, "customer_id không hợp lệ")
		return
	}

	var (
		tripID               int
		tripDistance         int
		tripPrice            float64
		tripLatitude         float64
		tripLongitude        float64
		destinationLatitude  float64
		destinationLongitude float64
		tripStatusID         int
		statusText           sql.NullString
		driverID             sql.NullInt64
		driverFullName       sql.NullString
		driverUserName       sql.NullString
		driverPhone          sql.NullString
		licensePlate         sql.NullString
		vehicleType          sql.NullString
	)

	err = db.QueryRowContext(r.Context(), `
		SELECT
			t.trip_id,
			t.trip_distance,
			t.trip_price,
			t.trip_latitude,
			t.trip_longitude,
			t.destination_latitude,
			t.destination_longitude,
			t.trip_status_id,
			ts.status,
			t.driver_id,
			dp.full_name,
			dp.user_name,
			dp.phone_number,
			d.licensePlate,
			vt.type
		FROM Trip t
		LEFT JOIN TripStatus ts ON ts.trip_status_id = t.trip_status_id
		LEFT JOIN Profile dp ON dp.profile_id = t.driver_id
		LEFT JOIN Driver d ON d.driver_id = t.driver_id
		LEFT JOIN VehicleType vt ON vt.id = d.vehicleType_id
		WHERE t.customer_id = ?
		  AND t.trip_status_id IN (?, ?, ?)
		ORDER BY t.trip_id DESC
		LIMIT 1
	`, customerID, tripStatusPendingV2, tripStatusAcceptedV2, tripStatusGoingV2).Scan(
		&tripID,
		&tripDistance,
		&tripPrice,
		&tripLatitude,
		&tripLongitude,
		&destinationLatitude,
		&destinationLongitude,
		&tripStatusID,
		&statusText,
		&driverID,
		&driverFullName,
		&driverUserName,
		&driverPhone,
		&licensePlate,
		&vehicleType,
	)

	if err == sql.ErrNoRows {
		w.WriteHeader(http.StatusOK)
		_ = json.NewEncoder(w).Encode(map[string]interface{}{
			"data":    nil,
			"message": "Khách hàng không có chuyến đi đang hoạt động",
		})
		return
	}
	if err != nil {
		log.Printf("Lỗi lấy chuyến đang hoạt động của customer %d: %v", customerID, err)
		tripJSONErrorV2(w, http.StatusInternalServerError, "Không thể lấy chuyến đi đang hoạt động")
		return
	}

	var driverIDValue interface{}
	if driverID.Valid {
		driverIDValue = driverID.Int64
	}

	w.WriteHeader(http.StatusOK)
	_ = json.NewEncoder(w).Encode(map[string]interface{}{
		"data": map[string]interface{}{
			"trip_id":               tripID,
			"customer_id":           customerID,
			"trip_distance":         tripDistance,
			"trip_price":            tripPrice,
			"trip_latitude":         tripLatitude,
			"trip_longitude":        tripLongitude,
			"destination_latitude":  destinationLatitude,
			"destination_longitude": destinationLongitude,
			"trip_status_id":        tripStatusID,
			"status_text":           parseNullString(statusText),
			"driver_id":             driverIDValue,
			"driver_full_name":      parseNullString(driverFullName),
			"driver_user_name":      parseNullString(driverUserName),
			"driver_phone":          parseNullString(driverPhone),
			"license_plate":         parseNullString(licensePlate),
			"vehicle_type":          parseNullString(vehicleType),
		},
		"message": "Lấy chuyến đi đang hoạt động thành công",
	})
}

type bookTripRequestV2 struct {
	CustomerID           int     `json:"customer_id"`
	TripDistance         int     `json:"trip_distance"`
	TripLatitude         float64 `json:"trip_latitude"`
	TripLongitude        float64 `json:"trip_longitude"`
	DestinationLatitude  float64 `json:"destination_latitude"`
	DestinationLongitude float64 `json:"destination_longitude"`
}

func bookTripV2(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")

	var req bookTripRequestV2
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		tripJSONErrorV2(w, http.StatusBadRequest, "Dữ liệu JSON không hợp lệ")
		return
	}

	if req.CustomerID <= 0 || req.TripDistance <= 0 ||
		!validCoordinateV2(req.TripLatitude, req.TripLongitude) ||
		!validCoordinateV2(req.DestinationLatitude, req.DestinationLongitude) {
		tripJSONErrorV2(w, http.StatusBadRequest, "Vui lòng nhập customer_id, trip_distance và tọa độ điểm đi/điểm đến hợp lệ")
		return
	}

	var pricePerKm int
	err := db.QueryRow(
		"SELECT price_per_km FROM PriceConfig WHERE ? >= `from` AND ? <= `to` LIMIT 1",
		req.TripDistance, req.TripDistance,
	).Scan(&pricePerKm)
	if err == sql.ErrNoRows {
		pricePerKm = 10000
	} else if err != nil {
		log.Printf("Lỗi lấy PriceConfig: %v", err)
		tripJSONErrorV2(w, http.StatusInternalServerError, "Lỗi hệ thống khi tính toán giá tiền")
		return
	}
	totalPrice := float64(req.TripDistance) * float64(pricePerKm)

	tx, err := db.BeginTx(r.Context(), nil)
	if err != nil {
		tripJSONErrorV2(w, http.StatusInternalServerError, "Không thể khởi tạo giao dịch đặt chuyến")
		return
	}
	defer tx.Rollback()

	var lockedCustomerID int
	err = tx.QueryRowContext(
		r.Context(),
		"SELECT customer_id FROM Customer WHERE customer_id = ? FOR UPDATE",
		req.CustomerID,
	).Scan(&lockedCustomerID)
	if err == sql.ErrNoRows {
		tripJSONErrorV2(w, http.StatusNotFound, "Không tìm thấy khách hàng")
		return
	}
	if err != nil {
		log.Printf("Lỗi khóa Customer khi đặt chuyến: %v", err)
		tripJSONErrorV2(w, http.StatusInternalServerError, "Không thể kiểm tra trạng thái khách hàng")
		return
	}

	var cancelledToday int
	err = tx.QueryRowContext(r.Context(), `
		SELECT COUNT(*)
		FROM Trip
		WHERE customer_id = ?
		  AND trip_status_id = ?
		  AND time >= CURDATE()
		  AND time < CURDATE() + INTERVAL 1 DAY
	`, req.CustomerID, tripStatusCancelV2).Scan(&cancelledToday)
	if err != nil {
		log.Printf("Lỗi đếm số chuyến Customer %d đã hủy hôm nay: %v", req.CustomerID, err)
		tripJSONErrorV2(w, http.StatusInternalServerError, "Không thể kiểm tra số lần hủy chuyến hôm nay")
		return
	}
	if cancelledToday >= 8 {
		_ = tx.Rollback()
		userMessage := "Bạn đã hủy quá nhiều chuyến hôm nay. Sang ngày mai bạn mới có thể đặt chuyến tiếp theo."
		driverMessage := fmt.Sprintf(
			"Khách hàng #%d đã hủy %d chuyến trong hôm nay và hiện không thể đặt chuyến mới. Khách hàng có thể đặt lại từ ngày mai.",
			req.CustomerID, cancelledToday,
		)
		broadcastAllDriversV2(map[string]interface{}{
			"type":         "customer_booking_blocked",
			"customer_id":  req.CustomerID,
			"cancel_count": cancelledToday,
			"message":      driverMessage,
		})
		tripJSONErrorV2(w, http.StatusTooManyRequests, userMessage)
		return
	}

	var activeTripID int
	var activeTripStatusID int
	err = tx.QueryRowContext(
		r.Context(),
		`SELECT trip_id, trip_status_id
		 FROM Trip
		 WHERE customer_id = ? AND trip_status_id IN (?, ?, ?)
		 ORDER BY trip_id DESC
		 LIMIT 1`,
		req.CustomerID,
		tripStatusPendingV2,
		tripStatusAcceptedV2,
		tripStatusGoingV2,
	).Scan(&activeTripID, &activeTripStatusID)
	if err == nil {
		tripJSONErrorV2(w, http.StatusConflict, fmt.Sprintf(
			"Bạn đang có chuyến đi chưa hoàn thành (trip_id: %d, status_id: %d). Vui lòng hoàn thành hoặc hủy chuyến hiện tại trước khi đặt chuyến mới",
			activeTripID, activeTripStatusID,
		))
		return
	}
	if err != sql.ErrNoRows {
		log.Printf("Lỗi kiểm tra chuyến đang hoạt động của Customer %d: %v", req.CustomerID, err)
		tripJSONErrorV2(w, http.StatusInternalServerError, "Không thể kiểm tra chuyến đi hiện tại")
		return
	}

	insertQuery := `
		INSERT INTO Trip (
			trip_distance, trip_price, customer_id, driver_id, trip_status_id,
			trip_latitude, trip_longitude, destination_latitude, destination_longitude, ` + "`time`" + `
		)
		VALUES (?, ?, ?, NULL, ?, ?, ?, ?, ?, NOW())
	`
	result, err := tx.ExecContext(
		r.Context(), insertQuery,
		req.TripDistance, totalPrice, req.CustomerID, tripStatusPendingV2,
		req.TripLatitude, req.TripLongitude,
		req.DestinationLatitude, req.DestinationLongitude,
	)
	if err != nil {
		log.Printf("Lỗi INSERT Trip: %v", err)
		tripJSONErrorV2(w, http.StatusInternalServerError, "Không thể lưu chuyến đi")
		return
	}

	lastInsertID, err := result.LastInsertId()
	if err != nil {
		tripJSONErrorV2(w, http.StatusInternalServerError, "Không thể lấy trip_id vừa tạo")
		return
	}
	tripID := int(lastInsertID)

	if _, err = tx.ExecContext(
		r.Context(),
		"UPDATE Customer SET latitude = ?, longitude = ? WHERE customer_id = ?",
		req.TripLatitude, req.TripLongitude, req.CustomerID,
	); err != nil {
		log.Printf("Lỗi cập nhật tọa độ Customer: %v", err)
		tripJSONErrorV2(w, http.StatusInternalServerError, "Không thể cập nhật vị trí khách hàng")
		return
	}

	var statusText string
	if err = tx.QueryRowContext(
		r.Context(), "SELECT status FROM TripStatus WHERE trip_status_id = ?", tripStatusPendingV2,
	).Scan(&statusText); err != nil {
		log.Printf("Lỗi lấy TripStatus: %v", err)
		tripJSONErrorV2(w, http.StatusInternalServerError, "Không thể lấy trạng thái chuyến đi")
		return
	}

	if err = tx.Commit(); err != nil {
		log.Printf("Lỗi commit bookTrip: %v", err)
		tripJSONErrorV2(w, http.StatusInternalServerError, "Không thể xác nhận chuyến đi")
		return
	}

	notifiedCount, notifyErr := notifyAvailableDriversV2(tripID, req, totalPrice)
	if notifyErr != nil {
		log.Printf("Lỗi tìm/gửi chuyến mới cho Driver: %v", notifyErr)
	}

	message := "Đã tạo chuyến đi. Đang chờ tài xế online gửi vị trí realtime"
	if notifiedCount > 0 {
		message = fmt.Sprintf("Đã gửi chuyến đi đến %d tài xế đang online; Flutter tự kiểm tra bán kính 5km", notifiedCount)
	}

	w.WriteHeader(http.StatusCreated)
	_ = json.NewEncoder(w).Encode(map[string]interface{}{
		"data": map[string]interface{}{
			"trip_id":               tripID,
			"customer_id":           req.CustomerID,
			"trip_distance":         req.TripDistance,
			"trip_price":            totalPrice,
			"trip_status_id":        tripStatusPendingV2,
			"status_text":           statusText,
			"trip_latitude":         req.TripLatitude,
			"trip_longitude":        req.TripLongitude,
			"destination_latitude":  req.DestinationLatitude,
			"destination_longitude": req.DestinationLongitude,
			"notified_driver_count": notifiedCount,
			"message":               message,
		},
	})
}

func notifyAvailableDriversV2(tripID int, req bookTripRequestV2, tripPrice float64) (int, error) {
	rows, err := db.Query(`SELECT driver_id FROM Driver WHERE active = 1`)
	if err != nil {
		return 0, err
	}
	var driverIDs []int
	for rows.Next() {
		var driverID int
		if err := rows.Scan(&driverID); err != nil {
			_ = rows.Close()
			return 0, err
		}
		driverIDs = append(driverIDs, driverID)
	}
	if err := rows.Err(); err != nil {
		_ = rows.Close()
		return 0, err
	}
	_ = rows.Close()

	notifiedCount := 0
	for _, driverID := range driverIDs {
		tx, err := db.Begin()
		if err != nil {
			return notifiedCount, err
		}
		var active int
		err = tx.QueryRow(`SELECT active FROM Driver WHERE driver_id = ? FOR UPDATE`, driverID).Scan(&active)
		if err != nil || active != 1 {
			_ = tx.Rollback()
			continue
		}
		var busyCount int
		err = tx.QueryRow(`
			SELECT COUNT(*) FROM Trip
			WHERE driver_id = ? AND trip_status_id IN (?, ?)
		`, driverID, tripStatusAcceptedV2, tripStatusGoingV2).Scan(&busyCount)
		if err != nil || busyCount > 0 {
			_ = tx.Rollback()
			continue
		}

		message := map[string]interface{}{
			"type": "new_trip",
			"data": map[string]interface{}{
				"trip_id":               tripID,
				"customer_id":           req.CustomerID,
				"trip_distance":         req.TripDistance,
				"trip_price":            tripPrice,
				"trip_latitude":         req.TripLatitude,
				"trip_longitude":        req.TripLongitude,
				"destination_latitude":  req.DestinationLatitude,
				"destination_longitude": req.DestinationLongitude,
			},
		}
		sent := sendDriverMessageV2(driverID, message)
		if err := tx.Commit(); err != nil {
			return notifiedCount, err
		}
		if sent {
			notifiedCount++
		}
	}
	return notifiedCount, nil
}

func sendPendingTripsToDriverV2(driverID int, client *tripSocketClientV2) error {
	var busyCount int
	err := db.QueryRow(`
		SELECT COUNT(*) FROM Trip
		WHERE driver_id = ? AND trip_status_id IN (?, ?)
	`, driverID, tripStatusAcceptedV2, tripStatusGoingV2).Scan(&busyCount)
	if err != nil {
		return fmt.Errorf("kiểm tra trạng thái bận của driver %d: %w", driverID, err)
	}
	if busyCount > 0 {
		return nil
	}

	type pendingTripV2 struct {
		TripID               int
		CustomerID           int
		TripDistance         int
		TripPrice            float64
		TripLatitude         float64
		TripLongitude        float64
		DestinationLatitude  float64
		DestinationLongitude float64
	}

	rows, err := db.Query(`
		SELECT trip_id, customer_id, trip_distance, trip_price,
		       trip_latitude, trip_longitude,
		       destination_latitude, destination_longitude
		FROM Trip
		WHERE trip_status_id = ? AND driver_id IS NULL
		ORDER BY trip_id ASC
	`, tripStatusPendingV2)
	if err != nil {
		return fmt.Errorf("lấy danh sách chuyến đang chờ cho driver %d: %w", driverID, err)
	}

	var pendingTrips []pendingTripV2
	for rows.Next() {
		var trip pendingTripV2
		if err := rows.Scan(
			&trip.TripID,
			&trip.CustomerID,
			&trip.TripDistance,
			&trip.TripPrice,
			&trip.TripLatitude,
			&trip.TripLongitude,
			&trip.DestinationLatitude,
			&trip.DestinationLongitude,
		); err != nil {
			_ = rows.Close()
			return fmt.Errorf("đọc chuyến đang chờ cho driver %d: %w", driverID, err)
		}
		pendingTrips = append(pendingTrips, trip)
	}
	if err := rows.Err(); err != nil {
		_ = rows.Close()
		return fmt.Errorf("duyệt danh sách chuyến đang chờ cho driver %d: %w", driverID, err)
	}
	if err := rows.Close(); err != nil {
		return fmt.Errorf("đóng danh sách chuyến đang chờ cho driver %d: %w", driverID, err)
	}

	for _, trip := range pendingTrips {
		message := map[string]interface{}{
			"type": "new_trip",
			"data": map[string]interface{}{
				"trip_id":               trip.TripID,
				"customer_id":           trip.CustomerID,
				"trip_distance":         trip.TripDistance,
				"trip_price":            trip.TripPrice,
				"trip_latitude":         trip.TripLatitude,
				"trip_longitude":        trip.TripLongitude,
				"destination_latitude":  trip.DestinationLatitude,
				"destination_longitude": trip.DestinationLongitude,
			},
		}
		if err := client.writeJSON(message); err != nil {
			return fmt.Errorf("gửi trip %d cho driver %d: %w", trip.TripID, driverID, err)
		}
	}

	if len(pendingTrips) > 0 {
		log.Printf("Đã gửi lại %d chuyến đang chờ cho driver %d", len(pendingTrips), driverID)
	}
	return nil
}

func handleDriverTripNotificationsV2(w http.ResponseWriter, r *http.Request) {
	driverID, err := strconv.Atoi(r.URL.Query().Get("driver_id"))
	if err != nil || driverID <= 0 {
		http.Error(w, "driver_id không hợp lệ", http.StatusBadRequest)
		return
	}
	var active int
	if err := db.QueryRow("SELECT active FROM Driver WHERE driver_id = ?", driverID).Scan(&active); err != nil {
		http.Error(w, "Không tìm thấy tài xế", http.StatusNotFound)
		return
	}
	if active != 1 {
		http.Error(w, "Tài khoản tài xế chưa được duyệt hoạt động", http.StatusForbidden)
		return
	}

	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Printf("Không thể mở WebSocket nhận chuyến cho driver %d: %v", driverID, err)
		return
	}
	client := &tripSocketClientV2{conn: conn}
	addDriverTripClientV2(driverID, client)
	log.Printf("Driver %d đã kết nối WebSocket nhận chuyến", driverID)

	defer func() {
		removeDriverTripClientV2(driverID, client)
		_ = conn.Close()
		log.Printf("Driver %d đã ngắt WebSocket nhận chuyến", driverID)
	}()

	if err := sendPendingTripsToDriverV2(driverID, client); err != nil {
		log.Printf("Không thể gửi lại chuyến đang chờ cho driver %d: %v", driverID, err)
	}

	for {
		_, rawMessage, err := conn.ReadMessage()
		if err != nil {
			break
		}
		if err := handleDriverProximityMessageV2(driverID, rawMessage); err != nil {
			log.Printf("Driver %d gửi proximity event lỗi: %v", driverID, err)
		}
	}
}

func handleDriverProximityMessageV2(driverID int, rawMessage []byte) error {
	var message struct {
		Type      string  `json:"type"`
		TripID    int     `json:"trip_id"`
		Latitude  float64 `json:"latitude"`
		Longitude float64 `json:"longitude"`
	}
	if err := json.Unmarshal(rawMessage, &message); err != nil {
		return err
	}
	if (message.Type != "driver_nearby" && message.Type != "driver_out_of_range") || message.TripID <= 0 {
		return nil
	}
	if !validCoordinateV2(message.Latitude, message.Longitude) {
		return fmt.Errorf("tọa độ không hợp lệ")
	}

	var active, statusID int
	err := db.QueryRow(`
		SELECT d.active, t.trip_status_id
		FROM Driver d
		JOIN Trip t ON t.trip_id = ?
		WHERE d.driver_id = ?
	`, message.TripID, driverID).Scan(&active, &statusID)
	if err != nil {
		return err
	}
	if active != 1 || statusID != tripStatusPendingV2 {
		return nil
	}

	if message.Type == "driver_nearby" {
		var busyCount int
		if err := db.QueryRow(`
			SELECT COUNT(*) FROM Trip
			WHERE driver_id = ? AND trip_status_id IN (?, ?)
		`, driverID, tripStatusAcceptedV2, tripStatusGoingV2).Scan(&busyCount); err != nil {
			return err
		}
		if busyCount > 0 {
			return nil
		}
	}

	broadcastCustomerTripV2(message.TripID, map[string]interface{}{
		"type": message.Type, "trip_id": message.TripID,
		"driver_id": driverID,
		"latitude":  message.Latitude, "longitude": message.Longitude,
	})
	return nil
}

func handleUserTrackingV2(w http.ResponseWriter, r *http.Request) {
	tripID, err := strconv.Atoi(mux.Vars(r)["trip_id"])
	if err != nil || tripID <= 0 {
		http.Error(w, "trip_id không hợp lệ", http.StatusBadRequest)
		return
	}

	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Printf("Không thể mở WebSocket theo dõi trip %d: %v", tripID, err)
		return
	}
	client := &tripSocketClientV2{conn: conn}
	addCustomerTripClientV2(tripID, client)

	var driverID sql.NullInt64
	var statusID int
	err = db.QueryRow(`
		SELECT driver_id, trip_status_id FROM Trip WHERE trip_id = ?
	`, tripID).Scan(&driverID, &statusID)
	if err == nil {
		if driverID.Valid && (statusID == tripStatusAcceptedV2 || statusID == tripStatusGoingV2) {
			eventType := "trip_accepted"
			if statusID == tripStatusGoingV2 {
				eventType = "trip_started"
			}
			_ = client.writeJSON(map[string]interface{}{
				"type": eventType, "trip_id": tripID, "driver_id": driverID.Int64,
			})
		}
	} else if err != sql.ErrNoRows {
		log.Printf("Lỗi lấy trạng thái ban đầu của trip %d: %v", tripID, err)
	}

	defer func() {
		removeCustomerTripClientV2(tripID, client)
		_ = conn.Close()
	}()
	for {
		if _, _, err := conn.ReadMessage(); err != nil {
			break
		}
	}
}

func handleDriverLocationStreamV2(w http.ResponseWriter, r *http.Request) {
	driverID, err := strconv.Atoi(r.URL.Query().Get("driver_id"))
	if err != nil || driverID <= 0 {
		http.Error(w, "driver_id không hợp lệ", http.StatusBadRequest)
		return
	}
	var active int
	if err := db.QueryRow("SELECT active FROM Driver WHERE driver_id = ?", driverID).Scan(&active); err != nil || active != 1 {
		http.Error(w, "Tài khoản tài xế không hợp lệ hoặc chưa được duyệt", http.StatusForbidden)
		return
	}

	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Printf("Không thể mở WebSocket GPS Driver %d: %v", driverID, err)
		return
	}
	defer conn.Close()

	for {
		_, rawMessage, err := conn.ReadMessage()
		if err != nil {
			break
		}
		var update struct {
			TripID    int     `json:"trip_id"`
			Latitude  float64 `json:"latitude"`
			Longitude float64 `json:"longitude"`
		}
		if err := json.Unmarshal(rawMessage, &update); err != nil || !validCoordinateV2(update.Latitude, update.Longitude) {
			_ = conn.WriteJSON(map[string]string{"type": "error", "message": "GPS JSON hoặc tọa độ không hợp lệ"})
			continue
		}
		if update.TripID <= 0 {
			continue
		}

		var assigned int
		err = db.QueryRow(`
			SELECT COUNT(*) FROM Trip
			WHERE trip_id = ? AND driver_id = ? AND trip_status_id IN (?, ?)
		`, update.TripID, driverID, tripStatusAcceptedV2, tripStatusGoingV2).Scan(&assigned)
		if err != nil || assigned == 0 {
			continue
		}
		broadcastCustomerTripV2(update.TripID, map[string]interface{}{
			"type": "driver_location", "trip_id": update.TripID,
			"driver_id": driverID,
			"latitude":  update.Latitude, "longitude": update.Longitude,
		})
	}
}

type acceptTripRequestV2 struct {
	DriverID int `json:"driver_id"`
}

func acceptTripV2(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	tripID, err := strconv.Atoi(mux.Vars(r)["id"])
	if err != nil || tripID <= 0 {
		tripJSONErrorV2(w, http.StatusBadRequest, "trip_id không hợp lệ")
		return
	}

	var req acceptTripRequestV2
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.DriverID <= 0 {
		tripJSONErrorV2(w, http.StatusBadRequest, "Vui lòng truyền driver_id hợp lệ")
		return
	}

	tx, err := db.BeginTx(r.Context(), nil)
	if err != nil {
		tripJSONErrorV2(w, http.StatusInternalServerError, "Không thể khởi tạo giao dịch nhận chuyến")
		return
	}
	defer tx.Rollback()

	var customerID, tripStatusID int
	var tripPrice float64
	var currentDriverID sql.NullInt64
	err = tx.QueryRowContext(r.Context(), `
		SELECT customer_id, trip_status_id, driver_id, trip_price
		FROM Trip WHERE trip_id = ? FOR UPDATE
	`, tripID).Scan(&customerID, &tripStatusID, &currentDriverID, &tripPrice)
	if err == sql.ErrNoRows {
		tripJSONErrorV2(w, http.StatusNotFound, "Không tìm thấy chuyến đi")
		return
	}
	if err != nil {
		log.Printf("Lỗi lock Trip %d: %v", tripID, err)
		tripJSONErrorV2(w, http.StatusInternalServerError, "Không thể kiểm tra chuyến đi")
		return
	}
	if tripStatusID != tripStatusPendingV2 || currentDriverID.Valid {
		tripJSONErrorV2(w, http.StatusConflict, "Chuyến đi đã được tài xế khác nhận hoặc không còn ở trạng thái chờ")
		return
	}

	var active int
	err = tx.QueryRowContext(r.Context(), `
		SELECT active FROM Driver WHERE driver_id = ? FOR UPDATE
	`, req.DriverID).Scan(&active)
	if err == sql.ErrNoRows {
		tripJSONErrorV2(w, http.StatusNotFound, "Không tìm thấy tài xế")
		return
	}
	if err != nil {
		log.Printf("Lỗi lock Driver %d: %v", req.DriverID, err)
		tripJSONErrorV2(w, http.StatusInternalServerError, "Không thể kiểm tra tài xế")
		return
	}
	if active != 1 {
		tripJSONErrorV2(w, http.StatusForbidden, "Tài khoản tài xế chưa được duyệt")
		return
	}
	if !isDriverConnectedV2(req.DriverID) {
		tripJSONErrorV2(w, http.StatusConflict, "Tài xế đang offline hoặc mất kết nối")
		return
	}

	var busyCount int
	if err := tx.QueryRowContext(r.Context(), `
		SELECT COUNT(*) FROM Trip
		WHERE driver_id = ? AND trip_status_id IN (?, ?)
	`, req.DriverID, tripStatusAcceptedV2, tripStatusGoingV2).Scan(&busyCount); err != nil {
		tripJSONErrorV2(w, http.StatusInternalServerError, "Không thể kiểm tra trạng thái bận/rảnh của tài xế")
		return
	}
	if busyCount > 0 {
		tripJSONErrorV2(w, http.StatusConflict, "Bạn đang thực hiện một chuyến đi khác")
		return
	}

	var walletMoney sql.NullFloat64
	err = tx.QueryRowContext(r.Context(), `
		SELECT money FROM DriverWallet WHERE driver_id = ? FOR UPDATE
	`, req.DriverID).Scan(&walletMoney)
	if err != nil && err != sql.ErrNoRows {
		log.Printf("Lỗi kiểm tra ví Driver %d: %v", req.DriverID, err)
		tripJSONErrorV2(w, http.StatusInternalServerError, "Không thể kiểm tra số dư ví tài xế")
		return
	}
	walletBalance := 0.0
	if walletMoney.Valid {
		walletBalance = walletMoney.Float64
	}
	if walletBalance < tripPrice {
		walletMessage := fmt.Sprintf(
			"Số dư ví không đủ để nhận chuyến này. Số dư hiện tại: %.0fđ, cần tối thiểu: %.0fđ.",
			walletBalance, tripPrice,
		)
		sendDriverMessageV2(req.DriverID, map[string]interface{}{
			"type":           "insufficient_wallet_balance",
			"trip_id":        tripID,
			"wallet_balance": walletBalance,
			"trip_price":     tripPrice,
			"message":        walletMessage,
		})
		tripJSONErrorV2(w, http.StatusPaymentRequired, walletMessage)
		return
	}

	result, err := tx.ExecContext(r.Context(), `
		UPDATE Trip SET driver_id = ?, trip_status_id = ?
		WHERE trip_id = ? AND trip_status_id = ? AND driver_id IS NULL
	`, req.DriverID, tripStatusAcceptedV2, tripID, tripStatusPendingV2)
	if err != nil {
		log.Printf("Lỗi cập nhật Driver nhận Trip: %v", err)
		tripJSONErrorV2(w, http.StatusInternalServerError, "Không thể nhận chuyến đi")
		return
	}
	rowsAffected, _ := result.RowsAffected()
	if rowsAffected != 1 {
		tripJSONErrorV2(w, http.StatusConflict, "Chuyến đi vừa được tài xế khác nhận")
		return
	}

	if err := tx.Commit(); err != nil {
		log.Printf("Lỗi commit acceptTrip: %v", err)
		tripJSONErrorV2(w, http.StatusInternalServerError, "Không thể xác nhận nhận chuyến")
		return
	}

	acceptedEvent := map[string]interface{}{
		"type":      "trip_accepted",
		"trip_id":   tripID,
		"driver_id": req.DriverID,
	}
	broadcastCustomerTripV2(tripID, acceptedEvent)
	broadcastAllDriversV2(map[string]interface{}{
		"type":      "trip_taken",
		"trip_id":   tripID,
		"driver_id": req.DriverID,
	})

	w.WriteHeader(http.StatusOK)
	_ = json.NewEncoder(w).Encode(map[string]interface{}{
		"data": map[string]interface{}{
			"trip_id":   tripID,
			"driver_id": req.DriverID,
			"status":    "ACCEPTED",
			"message":   "Nhận chuyến thành công",
		},
	})
}

func startTripV2(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	tripID, err := strconv.Atoi(mux.Vars(r)["id"])
	if err != nil || tripID <= 0 {
		tripJSONErrorV2(w, http.StatusBadRequest, "trip_id không hợp lệ")
		return
	}
	var req acceptTripRequestV2
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.DriverID <= 0 {
		tripJSONErrorV2(w, http.StatusBadRequest, "Vui lòng truyền driver_id hợp lệ")
		return
	}

	result, err := db.Exec(`
		UPDATE Trip SET trip_status_id = ?
		WHERE trip_id = ? AND driver_id = ? AND trip_status_id = ?
	`, tripStatusGoingV2, tripID, req.DriverID, tripStatusAcceptedV2)
	if err != nil {
		tripJSONErrorV2(w, http.StatusInternalServerError, "Không thể bắt đầu chuyến đi")
		return
	}
	rowsAffected, _ := result.RowsAffected()
	if rowsAffected != 1 {
		tripJSONErrorV2(w, http.StatusConflict, "Chuyến đi không ở trạng thái ACCEPTED hoặc không thuộc tài xế này")
		return
	}
	broadcastCustomerTripV2(tripID, map[string]interface{}{"type": "trip_started", "trip_id": tripID, "driver_id": req.DriverID})
	_ = json.NewEncoder(w).Encode(map[string]interface{}{"message": "Bắt đầu chuyến đi thành công", "trip_id": tripID})
}

func completeTripV2(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	tripID, err := strconv.Atoi(mux.Vars(r)["id"])
	if err != nil || tripID <= 0 {
		tripJSONErrorV2(w, http.StatusBadRequest, "trip_id không hợp lệ")
		return
	}
	var req acceptTripRequestV2
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.DriverID <= 0 {
		tripJSONErrorV2(w, http.StatusBadRequest, "Vui lòng truyền driver_id hợp lệ")
		return
	}

	tx, err := db.BeginTx(r.Context(), nil)
	if err != nil {
		tripJSONErrorV2(w, http.StatusInternalServerError, "Không thể hoàn thành chuyến đi")
		return
	}
	defer tx.Rollback()

	result, err := tx.ExecContext(r.Context(), `
		UPDATE Trip SET trip_status_id = ?
		WHERE trip_id = ? AND driver_id = ? AND trip_status_id IN (?, ?)
	`, tripStatusCompletedV2, tripID, req.DriverID, tripStatusAcceptedV2, tripStatusGoingV2)
	if err != nil {
		tripJSONErrorV2(w, http.StatusInternalServerError, "Không thể hoàn thành chuyến đi")
		return
	}
	rowsAffected, err := result.RowsAffected()
	if err != nil {
		tripJSONErrorV2(w, http.StatusInternalServerError, "Không thể hoàn thành chuyến đi")
		return
	}
	if rowsAffected != 1 {
		tripJSONErrorV2(w, http.StatusConflict, "Chuyến đi không thuộc tài xế này hoặc đã kết thúc")
		return
	}

	var tripPrice sql.NullFloat64
	if err := tx.QueryRowContext(r.Context(),
		"SELECT trip_price FROM Trip WHERE trip_id = ?", tripID,
	).Scan(&tripPrice); err != nil || !tripPrice.Valid || tripPrice.Float64 < 0 {
		log.Printf("Lỗi lấy giá chuyến %d khi hoàn thành: %v", tripID, err)
		tripJSONErrorV2(w, http.StatusInternalServerError, "Không thể lấy giá chuyến đi")
		return
	}

	// Customers pay the driver in cash, so the platform takes its commission
	// out of the driver's wallet when the trip is completed.
	platformFee := int64(math.Round(tripPrice.Float64 * platformCommissionRate))
	if _, err := tx.ExecContext(r.Context(),
		"INSERT INTO DriverWallet (driver_id, money) VALUES (?, ?) "+
			"ON DUPLICATE KEY UPDATE money = COALESCE(money, 0) - ?",
		req.DriverID, -platformFee, platformFee,
	); err != nil {
		log.Printf("Lỗi trừ phí chuyến %d vào ví driver %d: %v", tripID, req.DriverID, err)
		tripJSONErrorV2(w, http.StatusInternalServerError, "Không thể trừ phí chuyến đi vào ví tài xế")
		return
	}

	var walletBalance int64
	if err := tx.QueryRowContext(r.Context(),
		"SELECT COALESCE(money, 0) FROM DriverWallet WHERE driver_id = ?", req.DriverID,
	).Scan(&walletBalance); err != nil {
		log.Printf("Lỗi đọc ví driver %d: %v", req.DriverID, err)
		tripJSONErrorV2(w, http.StatusInternalServerError, "Không thể hoàn thành chuyến đi")
		return
	}

	if err := tx.Commit(); err != nil {
		tripJSONErrorV2(w, http.StatusInternalServerError, "Không thể hoàn thành chuyến đi")
		return
	}

	broadcastCustomerTripV2(tripID, map[string]interface{}{"type": "trip_completed", "trip_id": tripID, "driver_id": req.DriverID})
	_ = json.NewEncoder(w).Encode(map[string]interface{}{
		"message":        "Hoàn thành chuyến đi thành công",
		"trip_id":        tripID,
		"trip_price":     tripPrice.Float64,
		"platform_fee":   platformFee,
		"wallet_balance": walletBalance,
	})
}

// platformCommissionRate is the share of each fare deducted from the driver's
// wallet when a cash trip is completed.
const platformCommissionRate = 0.30
