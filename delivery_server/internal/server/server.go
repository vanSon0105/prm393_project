package server

import (
	"database/sql"
	"fmt"
	_ "github.com/go-sql-driver/mysql"
	"github.com/gorilla/mux"
	"log"
	"net/http"
	"os"
)

func Run() {
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
	log.Fatal(http.ListenAndServe("0.0.0.0:8080", withWebCORS(r)))

}
