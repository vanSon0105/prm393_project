package main

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"net"
	"net/http"
	"strconv"
	"sync"

	_ "github.com/go-sql-driver/mysql"
	"github.com/gorilla/mux"
	"github.com/gorilla/websocket"
)

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

type Profile struct {
	ProfileID   int    `json:"profile_id"`
	FullName    string `json:"full_name"`
	PhoneNumber string `json:"phone_number"`
	Address     string `json:"address"`
	UserName    string `json:"user_name"`
	Password    string `json:"password"`
	Image       string `json:"image"`
	RoleID      int    `json:"role_id"`
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

func GetString(s *string) string {
	if s == nil {
		return ""
	}
	return *s
}

func main() {
	var err error
	dsn := "root:root@tcp(127.0.0.1:3306)/mydb"
	db, err = sql.Open("mysql", dsn)
	if err != nil {
		log.Fatal(err)
	}
	defer db.Close()
	err = db.Ping()
	if err != nil {
		log.Fatal("❌ Connect to MYSQL Failure: ", err)
	}

	// Nếu vượt qua được bước Ping, hệ thống sẽ in dòng này
	fmt.Println("✅ Connect to MYSQL Success")

	r := mux.NewRouter()

	//Role apis
	r.HandleFunc("/api/getRoles", getRole).Methods("GET")

	// Admin APIs
	r.HandleFunc("/api/admin/drivers/requests", getDriverRequests).Methods("GET")
	r.HandleFunc("/api/admin/drivers", getAllDrivers).Methods("GET")
	r.HandleFunc("/api/admin/drivers/{id}/approve", approveDriver).Methods("POST")
	r.HandleFunc("/api/admin/drivers/{id}/lock", lockDriver).Methods("POST")

	// User (Customer) APIs
	r.HandleFunc("/api/user/register", registerUser).Methods("POST")
	r.HandleFunc("/api/user/login", loginUser).Methods("POST")
	r.HandleFunc("/api/user/trips/book", bookTrip).Methods("POST")
	r.HandleFunc("/api/user/trips/{id}/cancel", cancelTrip).Methods("POST")
	r.HandleFunc("/api/user/drivers/review", reviewDriver).Methods("POST")

	// Driver APIs
	r.HandleFunc("/api/driver/register", registerDriver).Methods("POST")
	r.HandleFunc("/api/driver/login", loginDriver).Methods("POST")
	r.HandleFunc("/api/driver/trips/{id}/accept", acceptTrip).Methods("POST")
	r.HandleFunc("/api/driver/trips/{id}/complete", completeTrip).Methods("POST")

	// Customer connect to listener location of driver realtime
	r.HandleFunc("/ws/user/track/{trip_id}", handleUserTracking)

	// Driver push location to server realtime
	r.HandleFunc("/ws/driver/location", handleDriverLocationStream)

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

	// Nâng cấp kết nối HTTP thông thường thành kết nối song công WebSocket
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Println("Lỗi nâng cấp kết nối khách hàng:", err)
		return
	}

	// Đăng ký kết nối của khách hàng này vào hệ thống Hub theo dõi của Chuyến đi
	hub.Lock()
	hub.Customers[tripID] = append(hub.Customers[tripID], conn)
	hub.Unlock()

	log.Printf("Khách hàng đã kết nối thành công để theo dõi Trip ID: %d\n", tripID)

	// Giữ kết nối mở, dọn dẹp kết nối khi khách hàng tắt ứng dụng hoặc ngắt mạng
	defer func() {
		conn.Close()
		hub.Lock()
		// Tìm và xóa kết nối lỗi khỏi danh sách quản lý
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

	// Đọc tin nhắn rác từ client nếu có (bắt buộc để phát hiện trạng thái ngắt kết nối sớm)
	for {
		if _, _, err := conn.ReadMessage(); err != nil {
			break
		}
	}
}

// 2. Hàm dành cho Tài xế: Nhận tọa độ liên tục và chuyển tiếp cho khách
func handleDriverLocationStream(w http.ResponseWriter, r *http.Request) {
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Println("Lỗi nâng cấp kết nối tài xế:", err)
		return
	}
	defer conn.Close()

	log.Println("Tài xế đã thiết lập kết nối luồng tọa độ GPS real-time")

	for {
		// Vòng lặp liên tục đọc dữ liệu GPS dạng JSON từ thiết bị của tài xế gửi lên
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

		// Bước A: Cập nhật vị trí mới nhất của tài xế vào cơ sở dữ liệu MySQL
		_, err = db.Exec("UPDATE Driver SET latitude = ?, longitude = ? WHERE driver_id = ?",
			update.Latitude, update.Longitude, update.DriverID)
		if err != nil {
			log.Println("Lỗi lưu tọa độ vào DB:", err)
		}

		// Bước B: Phát tín hiệu tọa độ này ngay lập tức cho tất cả khách hàng đang theo dõi Trip này
		hub.Lock()
		customers, exists := hub.Customers[update.TripID]
		hub.Unlock()

		if exists {
			for _, clientConn := range customers {
				// Gửi thẳng gói dữ liệu tọa độ xuống ứng dụng của Khách hàng
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
	// Logic: Select profiles with role_id = 3 and specific status (requires profile status field in DB)
	// Placeholder: returning all potential drivers
	rows, _ := db.Query("SELECT profile_id, full_name, user_name FROM Profile WHERE role_id = 3")
	defer rows.Close()
	// Logic to return list...
	w.WriteHeader(http.StatusOK)
}

func getAllDrivers(w http.ResponseWriter, r *http.Request) {
	// 1. Nhớ hứng biến err, không được dùng dấu gạch dưới _
	rows, err := db.Query("SELECT profile_id, full_name, phone_number, COALESCE(address, '') AS address, user_name, password, COALESCE(image, '') AS image, role_id FROM Profile WHERE role_id = 3")

	// 2. BẮT BUỘC KHẮC PHỤC: Kiểm tra nếu có lỗi thì dừng lại luôn, không chạy tiếp
	if err != nil {
		log.Printf("❌ Lỗi Query Database: %v", err)
		http.Error(w, "Lỗi kết nối hoặc truy vấn cơ sở dữ liệu", http.StatusInternalServerError)
		return
	}

	// 3. Đặt defer ngay SAU KHI đã chắc chắn rows không bị nil
	defer rows.Close()

	var drivers []Profile
	log.Print("Request get all drivers")

	for rows.Next() {
		var ProfileID int
		var FullName string
		var PhoneNumber string
		var Address string
		var UserName string
		var Password string
		var Image string
		var RoleId int

		err := rows.Scan(&ProfileID, &FullName, &PhoneNumber, &Address, &UserName, &Password, &Image, &RoleId)
		if err != nil {
			log.Printf("⚠️ Lỗi scan dòng dữ liệu: %v", err)
			continue
		}

		drivers = append(drivers, Profile{
			ProfileID:   ProfileID,
			FullName:    FullName,
			PhoneNumber: PhoneNumber,
			Address:     Address,
			UserName:    UserName,
			Password:    Password,
			Image:       Image,
			RoleID:      RoleId,
		})
	}

	// 4. Kiểm tra lỗi luồng sau khi chạy xong vòng lặp
	if err := rows.Err(); err != nil {
		log.Printf("❌ Lỗi luồng rows: %v", err)
		http.Error(w, "Lỗi xử lý luồng dữ liệu cơ sở dữ liệu", http.StatusInternalServerError)
		return
	}

	// 5. Trả dữ liệu JSON về client
	w.Header().Set("Content-Type", "application/json")
	apiResponse := struct {
		Data []Profile `json:"data"`
	}{
		Data: drivers,
	}

	jsonData, err := json.Marshal(apiResponse)
	if err != nil {
		http.Error(w, "Lỗi tạo chuỗi JSON", http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusOK)
	w.Write(jsonData)
}

func approveDriver(w http.ResponseWriter, r *http.Request) {
}

func lockDriver(w http.ResponseWriter, r *http.Request) {
}

// --- User Handlers ---
func registerUser(w http.ResponseWriter, r *http.Request) {
}

func loginUser(w http.ResponseWriter, r *http.Request) {
	type LoginRequest struct {
		UserName  string `json:"user_name"`
		Password  string `json:"password"`
		RoleValue string `json:"role_value"`
	}

	var req LoginRequest
	err := json.NewDecoder(r.Body).Decode(&req)
	if err != nil {
		http.Error(w, "Dữ liệu JSON không hợp lệ", http.StatusBadRequest)
		return
	}

	// 2. Tìm role_id từ bảng Role dựa trên roleValue
	var roleID int
	err = db.QueryRow("SELECT id FROM Role WHERE role_value = ?", req.RoleValue).Scan(&roleID)
	if err != nil {
		if err == sql.ErrNoRows {
			http.Error(w, "Role không tồn tại", http.StatusBadRequest)
		} else {
			http.Error(w, "Lỗi hệ thống", http.StatusInternalServerError)
		}
		return
	}

	// 3. Kiểm tra tài khoản trong bảng Profile (Khớp cả userName, password và roleID)
	// Áp dụng COALESCE cho các trường nullable để phòng ngừa lỗi Scan khi tài khoản mới đăng ký
	var p Profile
	var addressStr, imageStr string // Sử dụng biến string tạm thời

	query := `
		SELECT 
			profile_id, full_name, phone_number, 
			COALESCE(address, '') AS address, 
			user_name, password, 
			COALESCE(image, '') AS image, 
			role_id 
		FROM Profile 
		WHERE user_name = ? AND password = ? AND role_id = ?`

	err = db.QueryRow(query, req.UserName, req.Password, roleID).Scan(
		&p.ProfileID, &p.FullName, &p.PhoneNumber, &addressStr,
		&p.UserName, &p.Password, &imageStr, &p.RoleID,
	)

	if err != nil {
		if err == sql.ErrNoRows {
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusUnauthorized)
			w.Write([]byte(`{"message": "Tên đăng nhập, mật khẩu hoặc vai trò không chính xác"}`))
		} else {
			log.Printf("❌ Lỗi truy vấn Profile: %v", err)
			http.Error(w, "Lỗi xác thực hệ thống", http.StatusInternalServerError)
		}
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)

	apiResponse := struct {
		Message string  `json:"message"`
		Data    Profile `json:"data"`
	}{
		Message: "Đăng nhập thành công",
		Data:    p,
	}

	jsonData, _ := json.Marshal(apiResponse)
	w.Write(jsonData)
}

func bookTrip(w http.ResponseWriter, r *http.Request) {
}

func cancelTrip(w http.ResponseWriter, r *http.Request) {
}

func reviewDriver(w http.ResponseWriter, r *http.Request) {
}

// --- Driver Handlers ---
func registerDriver(w http.ResponseWriter, r *http.Request) {
}

func loginDriver(w http.ResponseWriter, r *http.Request) {
}

func acceptTrip(w http.ResponseWriter, r *http.Request) {
}

func completeTrip(w http.ResponseWriter, r *http.Request) {

}
