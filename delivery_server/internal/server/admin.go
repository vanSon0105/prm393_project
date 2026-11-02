package server

import (
	"context"
	"database/sql"
	"encoding/json"
	"log"
	"net/http"
)

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

	drivers := make([]DriverResponse, 0)
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

	drivers := make([]DriverResponse, 0)
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
