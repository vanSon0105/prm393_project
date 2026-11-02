package main

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"sync"

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

func getPublicBaseURL() string {
	if value := strings.TrimRight(os.Getenv("PUBLIC_BASE_URL"), "/"); value != "" {
		return value
	}
	return fmt.Sprintf("http://%s:8080", getLocalIP())
}

func parseNullString(ns sql.NullString) string {
	if !ns.Valid || ns.String == "" {
		return ""
	}
	return ns.String
}

func main() {
	var err error
	dsn := os.Getenv("DB_DSN")
	if dsn == "" {
		dsn = "root:root@tcp(127.0.0.1:3306)/mydb"
	}
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

	//Role apis
	r.HandleFunc("/api/getRoles", getRole).Methods("GET")

	// Admin APIs
	r.HandleFunc("/api/admin/drivers/requests", getDriverRequests).Methods("GET")
	r.HandleFunc("/api/admin/drivers", getAllDrivers).Methods("GET")
	r.HandleFunc("/api/admin/drivers/{id}/approve", approveDriver).Methods("POST")

	// User (Customer) APIs
	r.HandleFunc("/api/user/trips/book", bookTrip).Methods("POST")
	r.HandleFunc("/api/user/trips/{id}/cancel", cancelTrip).Methods("POST")
	r.HandleFunc("/api/user/drivers/review", reviewDriver).Methods("POST")

	// Driver APIs
	r.HandleFunc("/api/driver/trips/{id}/accept", acceptTrip).Methods("POST")
	r.HandleFunc("/api/driver/trips/{id}/complete", completeTrip).Methods("POST")

	// Driver, User, Admin Login/Register API
	r.HandleFunc("/api/user/login", loginUser).Methods("POST")
	r.HandleFunc("/api/user/register", registerUser).Methods("POST")

	// Customer connect to listener location of driver realtime
	r.HandleFunc("/ws/user/track/{trip_id}", handleUserTracking)

	// Driver push location to server realtime
	r.HandleFunc("/ws/driver/location", handleDriverLocationStream)

	fmt.Printf("🚀 Server đang chạy trên mạng Wi-Fi!\n")
	fmt.Printf("📱 Địa chỉ để nhập vào App: %s\n", getPublicBaseURL())
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

		_, err = db.Exec("UPDATE Driver SET latitude = ?, longitude = ? WHERE driver_id = ?",
			update.Latitude, update.Longitude, update.DriverID)
		if err != nil {
			log.Println("Lỗi lưu tọa độ vào DB:", err)
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

// --- Admin Handlers ---

func getDriverRequests(w http.ResponseWriter, r *http.Request) {
	baseImgURL := getPublicBaseURL() + "/image/"
	query := `
		SELECT 
			p.profile_id, p.full_name, p.phone_number, p.address, p.image,
			d.driving_license_front_side, d.driving_license_back_side, 
			d.front_side_of_the_identity_card, d.the_back_of_the_identity_card
		FROM Profile p
		INNER JOIN Driver d ON p.profile_id = d.driver_id
		WHERE d.active = 0
	`
	rows, err := db.Query(query)
	if err != nil {
		log.Printf("❌ Lỗi Query Database: %v", err)
		http.Error(w, "Lỗi kết nối hoặc truy vấn cơ sở dữ liệu", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var drivers []DriverResponse
	log.Print("Request get all request drivers")

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

func getAllDrivers(w http.ResponseWriter, r *http.Request) {
	baseImgURL := getPublicBaseURL() + "/image/"
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

	activeValue := 0
	if req.Status {
		activeValue = 1
	}

	updateQuery := "UPDATE Driver SET active = ? WHERE driver_id = ?"
	result, err := tx.ExecContext(ctx, updateQuery, activeValue, req.DriverID)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(struct {
			Error string `json:"error"`
		}{Error: "Lỗi hệ thống khi cập nhật trạng thái tài xế"})
		return
	}

	rowsAffected, _ := result.RowsAffected()
	if rowsAffected == 0 {
		w.WriteHeader(http.StatusNotFound)
		json.NewEncoder(w).Encode(struct {
			Error string `json:"error"`
		}{Error: "Không tìm thấy tài xế với driver_id đã cung cấp"})
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
		Role     string `json:"role"`
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

	if req.UserName == "" || req.Password == "" || req.Role == "" {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(map[string]string{"error": "Vui lòng nhập đầy đủ user_name, password và role"})
		return
	}

	var profileID int
	var dbPassword, dbRoleValue string

	queryProfile := `
		SELECT p.profile_id, p.password, r.role_value 
		FROM Profile p
		INNER JOIN Role r ON p.role_id = r.role_id
		WHERE p.user_name = ?
	`
	err = db.QueryRow(queryProfile, req.UserName).Scan(&profileID, &dbPassword, &dbRoleValue)

	if err == sql.ErrNoRows {
		w.WriteHeader(http.StatusNotFound)
		json.NewEncoder(w).Encode(map[string]string{"error": "Tài khoản không tồn tại trên hệ thống"})
		return
	} else if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(map[string]string{"error": "Lỗi hệ thống khi kiểm tra thông tin tài khoản"})
		return
	}

	if req.Role != dbRoleValue {
		w.WriteHeader(http.StatusForbidden)
		json.NewEncoder(w).Encode(map[string]string{"error": "Tài khoản không thuộc quyền truy cập (Role) này"})
		return
	}

	if dbPassword != req.Password {
		w.WriteHeader(http.StatusUnauthorized)
		json.NewEncoder(w).Encode(map[string]string{"error": "Mật khẩu không chính xác"})
		return
	}

	loginStatus := "APPROVED"
	msg := "Đăng nhập thành công"

	if req.Role == "DRIVER" {
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
			Role:      req.Role,
			Status:    loginStatus,
			Message:   msg,
		},
	}

	jsonData, _ := json.Marshal(apiResponse)
	w.WriteHeader(http.StatusOK)
	w.Write(jsonData)
}

func registerUser(w http.ResponseWriter, r *http.Request) {
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

	userName := r.FormValue("user_name")
	password := r.FormValue("password")
	role := r.FormValue("role")
	phoneNumber := r.FormValue("phone_number") // Lấy thêm số điện thoại từ request gửi lên

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
		json.NewEncoder(w).Encode(map[string]string{"error": "Lỗi hệ thống khi kiểm tra tài khoản"})
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
		json.NewEncoder(w).Encode(map[string]string{"error": "Lỗi hệ thống khi kiểm tra số điện thoại"})
		return
	}
	if phoneExists > 0 {
		w.WriteHeader(http.StatusConflict)
		json.NewEncoder(w).Encode(map[string]string{"error": "Số điện thoại này đã được đăng ký bởi một tài khoản khác"})
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

	profileQuery := "INSERT INTO Profile (user_name, password, phone_number, role_id) VALUES (?, ?, ?, ?)"
	res, err := tx.ExecContext(ctx, profileQuery, userName, password, phoneNumber, roleID)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(map[string]string{"error": "Lỗi khi lưu hồ sơ người dùng vào cơ sở dữ liệu"})
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
				driver_id, driving_license_front_side, driving_license_back_side, 
				front_side_of_the_identity_card, the_back_of_the_identity_card, active
			) VALUES (?, ?, ?, ?, ?, 0)
		`
		_, err = tx.ExecContext(ctx, driverQuery, newID, licenseFrontName, licenseBackName, idFrontName, idBackName)
		if err != nil {
			w.WriteHeader(http.StatusInternalServerError)
			json.NewEncoder(w).Encode(map[string]string{"error": "Lỗi lưu hồ sơ tài xế vào cơ sở dữ liệu"})
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
			"profile_id":   newID,
			"user_name":    userName,
			"phone_number": phoneNumber,
			"role":         role,
			"message":      msg,
		},
	}

	jsonData, _ := json.Marshal(apiResponse)
	w.WriteHeader(http.StatusCreated)
	w.Write(jsonData)
}
