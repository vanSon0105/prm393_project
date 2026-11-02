package server

import (
	"encoding/json"
	"net/http"
)

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
