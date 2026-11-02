# API examples

Run these from `delivery_server` after starting the API with `go run ./cmd/api`.

GetRole: curl -i http://localhost:8080/api/getRoles
GetALLDriver: curl -i http://localhost:8080/api/admin/drivers
GetALLRequestDriver: curl -i http://localhost:8080/api/admin/drivers/requests

Approved Driver :
curl -i -X POST http://localhost:8080/api/admin/drivers/1/approve \
-H "Content-Type: application/json" \
-d '{"driver_id": 2, "status": true, "reason": ""}'

Reject Driver:
curl -i -X POST http://localhost:8080/api/admin/drivers/1/approve \
-H "Content-Type: application/json" \
-d '{"driver_id": 2, "status": false, "reason": "Ảnh mặt sau của Căn cước công dân bị mờ, không nhìn rõ số"}'

Register Driver
curl -i -X POST http://localhost:8080/api/user/register \
  -F "user_name=driver_test_99" \
  -F "password=driver_password" \
  -F "role=DRIVER" \
  -F "phone_number=0901234567" \
  -F "driving_license_front_side=@testdata/sample_driver_license_front_side.jpg" \
  -F "driving_license_back_side=@testdata/sample_driver_license_back_side.jpg" \
  -F "front_side_of_the_identity_card=@testdata/sample_driver_front_side.jpg" \
  -F "the_back_of_the_identity_card=@testdata/sample_driver_back_side.png"

FormData formData = FormData.fromMap({
    "user_name": "tai_xe_cong_nghe",
    "password": "password123",
    "role": "DRIVER",
    "phone_number": "0901234567",
    
    // Đính kèm file vật lý từ bộ nhớ điện thoại sử dụng MultipartFile
    "driving_license_front_side": await MultipartFile.fromFile(
      "./path_anh_trong_dien_thoai/gplx_truoc.jpg", 
      filename: "gplx_truoc.jpg"
    ),
    "driving_license_back_side": await MultipartFile.fromFile(
      "./path_anh_trong_dien_thoai/gplx_sau.jpg", 
      filename: "gplx_sau.jpg"
    ),
    "front_side_of_the_identity_card": await MultipartFile.fromFile(
      "./path_anh_trong_dien_thoai/cccd_truoc.jpg", 
      filename: "cccd_truoc.jpg"
    ),
    "the_back_of_the_identity_card": await MultipartFile.fromFile(
      "./path_anh_trong_dien_thoai/cccd_sau.png", 
      filename: "cccd_sau.png"
    ),
  });

  Register User
  curl -i -X POST http://localhost:8080/api/user/register \
  -F "user_name=Customer" \
  -F "password=customer_password" \
  -F "role=CUSTOMER" \
  -F "phone_number=0907654321"

  FormData formData = FormData.fromMap({
    "user_name": "khach_hang_moi_123",
    "password": "my_secure_password",
    "phone_number": "0907654321",
    "role": "CUSTOMER", // Sử dụng chuỗi chữ đúng theo cấu hình server
  });
