package server

import (
	"encoding/json"
	"github.com/gorilla/mux"
	"github.com/gorilla/websocket"
	"log"
	"net/http"
	"strconv"
)

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
