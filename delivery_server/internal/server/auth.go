package server

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
)

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

	invalidCredentialsError := map[string]string{"error": "Tài khoản hoặc mật khẩu không chính xác"}

	if err == sql.ErrNoRows {
		w.WriteHeader(http.StatusUnauthorized)
		json.NewEncoder(w).Encode(invalidCredentialsError)
		return
	} else if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(map[string]string{"error": "Lỗi hệ thống khi kiểm tra thông tin tài khoản"})
		return
	}

	if dbPassword != req.Password || req.Role != dbRoleValue {
		w.WriteHeader(http.StatusUnauthorized)
		json.NewEncoder(w).Encode(invalidCredentialsError)
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
