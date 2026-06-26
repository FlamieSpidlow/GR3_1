class_name ThemedLevelProvider
extends RefCounted

const MIN_PLAYABLE_WORDS := 5
const MIN_STAGE_WORDS := 4
const BOARD_SIZE := 18
const OPTIMIZE_ATTEMPTS := 8
const PREFERRED_STAGE_COUNT := 3
const MANUAL_CLUES := preload("res://scripts/manual_clues.gd")

const CLUE_OVERRIDES: Dictionary = {
	"Bàn trang điểm": "Đồ nội thất có gương và ngăn kéo, thường dùng khi chải tóc hoặc chuẩn bị trước khi ra ngoài.",
	"Bao gối": "Lớp vải bọc bên ngoài ruột gối để giữ sạch và tạo cảm giác êm khi nằm.",
	"Chăn": "Tấm vải dày dùng để đắp khi ngủ hoặc khi trời lạnh.",
	"Công tắc điện": "Bộ phận dùng để bật hoặc tắt nguồn điện cho đèn và thiết bị.",
	"Cửa sổ": "Khoảng mở trên tường giúp phòng có ánh sáng và không khí.",
	"Đèn bàn": "Đèn nhỏ đặt trên bàn, thường dùng để đọc sách hoặc làm việc.",
	"Đèn ngủ": "Đèn ánh sáng dịu để trong phòng khi nghỉ ngơi ban đêm.",
	"Đệm": "Tấm lót êm đặt trên giường để nằm thoải mái hơn.",
	"Đồng hồ báo thức": "Thiết bị đặt giờ kêu để nhắc người dùng thức dậy.",
	"Giường": "Đồ nội thất chính trong phòng ngủ, dùng để nằm nghỉ.",
	"Giường hai tầng": "Loại giường có hai chỗ nằm xếp chồng lên nhau để tiết kiệm diện tích.",
	"Gối": "Vật mềm kê đầu khi ngủ.",
	"Gối ôm": "Gối dài dùng để ôm hoặc kê người khi nằm.",
	"Gương": "Bề mặt phản chiếu hình ảnh, thường dùng để soi.",
	"Màn cửa": "Tấm vải che cửa sổ để chắn sáng hoặc tạo riêng tư.",
	"Móc treo quần áo": "Vật dùng để treo áo quần cho gọn và ít nhăn.",
	"Ngăn kéo": "Hộc trượt ra vào trong tủ hoặc bàn để cất đồ nhỏ.",
	"Ra trải giường": "Tấm vải phủ lên đệm để giữ sạch chỗ nằm.",
	"Rương": "Hòm lớn có nắp, dùng để cất giữ đồ đạc.",
	"Tiếng ngáy": "Âm thanh phát ra khi một người thở lúc ngủ.",
	"Tủ quần áo": "Tủ lớn dùng để treo và cất quần áo.",
	"Ngáp": "Phản xạ há miệng hít sâu khi buồn ngủ hoặc mệt.",
	"Ngáy": "Thở phát ra âm thanh trong lúc ngủ.",
	"Ngủ": "Trạng thái nghỉ ngơi tự nhiên của cơ thể.",
	"Nằm mơ": "Trải nghiệm hình ảnh hoặc câu chuyện xuất hiện trong khi ngủ.",
	"Bảng kiểm tra thị lực": "Bảng có các chữ hoặc ký hiệu nhiều kích cỡ để đo khả năng nhìn.",
	"Băng keo cá nhân": "Miếng dán nhỏ dùng để che và bảo vệ vết thương nhẹ.",
	"Bông gòn": "Vật liệu mềm, thấm hút, thường dùng để lau hoặc sát khuẩn.",
	"Cái cáng": "Dụng cụ dùng để khiêng người bị thương hoặc bệnh nhân.",
	"Cái cân": "Dụng cụ đo khối lượng cơ thể hoặc đồ vật.",
	"Cái nạng": "Dụng cụ chống đỡ giúp người bị đau chân di chuyển.",
	"Cồn": "Dung dịch thường dùng để sát khuẩn.",
	"Dao mổ": "Dụng cụ sắc dùng trong phẫu thuật.",
	"Hộp cứu thương": "Hộp đựng vật dụng sơ cứu như băng, gạc và thuốc sát trùng.",
	"Kéo y tế": "Kéo dùng trong chăm sóc y tế, thường để cắt băng gạc.",
	"Khẩu trang y tế": "Vật che mũi miệng giúp hạn chế giọt bắn và bụi bẩn.",
	"Ống nghe": "Dụng cụ bác sĩ dùng để nghe tim, phổi hoặc âm thanh bên trong cơ thể.",
	"Ống tiêm": "Dụng cụ có kim dùng để tiêm thuốc hoặc lấy mẫu dịch.",
	"Máy đo huyết áp": "Thiết bị dùng để kiểm tra áp lực máu trong động mạch.",
	"Máy sốc điện": "Thiết bị cấp xung điện để hỗ trợ tim trong tình huống khẩn cấp.",
	"Mặt nạ ôxi": "Mặt nạ giúp đưa khí ôxi đến người cần hỗ trợ hô hấp.",
	"Nhiệt kế": "Dụng cụ đo nhiệt độ cơ thể.",
	"Que đè lưỡi": "Que dẹt dùng để giữ lưỡi khi khám họng.",
	"Que thử thai": "Dụng cụ kiểm tra dấu hiệu mang thai qua mẫu nước tiểu.",
	"Xe lăn": "Ghế có bánh xe giúp người khó đi lại di chuyển.",
}

const THEMES: Array[Dictionary] = [
	{
		"id": "bedroom",
		"title": "Phòng ngủ",
		"context": "nghỉ ngơi, đồ đạc cá nhân và không gian riêng tư",
		"words": ["Bàn trang điểm", "Bao gối", "Chăn", "Công tắc điện", "Cửa sổ", "Đèn bàn", "Đèn ngủ", "Đệm", "Đồng hồ báo thức", "Giường", "Giường hai tầng", "Gối", "Gối ôm", "Gương", "Màn cửa", "Móc treo quần áo", "Ngăn kéo", "Ra trải giường", "Rương", "Tiếng ngáy", "Tủ quần áo", "Ngáp", "Ngáy", "Ngủ", "Nằm mơ"],
	},
	{
		"id": "time",
		"title": "Thời gian",
		"context": "cách con người gọi tên, chia nhỏ và cảm nhận thời điểm",
		"words": ["Giây", "Phút", "Giờ", "Thứ", "Tuần", "Tháng", "Quý", "Năm", "Thập kỷ", "Thế kỷ", "Thiên niên kỷ", "Mùa", "Buổi sáng", "Buổi trưa", "Buổi chiều", "Buổi tối", "Nửa đêm", "Hoàng hôn", "Bình minh", "Ngày mai", "Ngày nghỉ", "Ngày lễ"],
	},
	{
		"id": "bathroom",
		"title": "Nhà tắm",
		"context": "vệ sinh cá nhân, nước và các vật dụng chăm sóc cơ thể",
		"words": ["Bàn chải", "Bọt xà phòng", "Bồn cầu", "Bồn rửa tay", "Bồn tắm", "Cống thoát nước", "Dao cạo râu", "Dầu gội đầu", "Dầu xả", "Giấy vệ sinh", "Gương", "Kem cạo râu", "Kem đánh răng", "Keo xịt tóc", "Khăn", "Lược", "Máy sấy tóc", "Móc treo", "Nhíp", "Nước súc miệng", "Sữa rửa mặt", "Sữa tắm", "Vòi nước", "Vòi sen", "Xà bông"],
	},
	{
		"id": "hairstyle",
		"title": "Các kiểu tóc",
		"context": "kiểu dáng, cách tạo hình và trạng thái của tóc",
		"words": ["Cạo trọc", "Đầu đinh", "Hói đầu", "Mái ngố", "Bím", "Búi", "Buộc hai bên", "Cá đối", "Chẻ ngôi giữa", "Dài", "Đuôi ngựa", "Gợn sóng", "Hai mái", "Húi cua", "Ngang vai", "Ngắn", "Nhuộm", "Thẳng", "Uốn lọn", "Xoăn"],
	},
	{
		"id": "folk_game",
		"title": "Trò chơi dân gian",
		"context": "hoạt động vui chơi quen thuộc trong sinh hoạt cộng đồng",
		"words": ["Bắn bi", "Bầu cua tôm cá", "Bịt mắt bắt dê", "Chọi gà", "Chơi chuyền", "Cờ caro", "Cờ cá ngựa", "Cờ người", "Cờ tướng", "Cờ vây", "Cướp cờ", "Đá cầu", "Đánh quay", "Đấu vật", "Đếm sao", "Đi cà kheo", "Kéo co", "Kéo cưa lừa xẻ", "Oẳn tù tì", "Ô ăn quan", "Mèo đuổi chuột", "Nhảy bao bố", "Nhảy dây", "Nhảy lò cò", "Nhảy sạp", "Rồng rắn lên mây", "Thả diều", "Trốn tìm"],
	},
	{
		"id": "weapon",
		"title": "Vũ khí",
		"context": "công cụ tấn công, phòng thủ hoặc gây sát thương",
		"words": ["Bình xịt hơi cay", "Bom", "Bồ cào", "Chùy", "Côn nhị khúc", "Cung tên", "Dao", "Đại bác", "Đạn", "Đao", "Đinh ba", "Giáo", "Khiên", "Kích", "Kiếm", "Lao", "Lưỡi lê", "Lựu đạn", "Mã tấu", "Máy bắn đá", "Mìn", "Ná", "Ngư lôi", "Nỏ", "Phi tiêu", "Rìu", "Roi da", "Súng cối", "Súng ngắn", "Súng trường", "Tên lửa", "Thuốc độc", "Thuốc nổ", "Thủy lôi"],
	},
	{
		"id": "mid_autumn",
		"title": "Trung thu",
		"context": "đêm rằm, trăng, lễ hội và ký ức tuổi thơ",
		"words": ["Chị Hằng", "Chú Cuội", "Thỏ ngọc", "Ông Địa", "Cây đa", "Cung trăng", "Trăng tròn", "Bánh trung thu", "Mặt nạ", "Đèn lồng", "Đèn ông sao", "Đèn cá chép", "Đèn kéo quân", "Tò he", "Lễ rước đèn", "Rước đèn", "Múa lân", "Múa rồng", "Ngắm trăng", "Phá cỗ"],
	},
	{
		"id": "living_room",
		"title": "Phòng khách",
		"context": "tiếp khách, sinh hoạt chung và đồ nội thất gia đình",
		"words": ["Âm ly", "Bàn sofa", "Bình hoa", "Bức ảnh", "Cây cảnh", "Đèn chùm", "Điều hòa", "Điều khiển tivi", "Đồng hồ treo tường", "Gạt tàn thuốc", "Ghế bành", "Ghế đẩu", "Ghế sô pha", "Kệ", "Lịch", "Loa", "Màn cửa", "Nệm lót ghế", "Quạt điện", "Quạt trần", "Thảm", "Thùng rác", "Tivi", "Tranh", "Tủ sách"],
	},
	{
		"id": "christmas",
		"title": "Giáng sinh",
		"context": "mùa lễ hội, trang trí, quà tặng và không khí cuối năm",
		"words": ["Bít tất", "Cây tầm gửi", "Cây thông", "Cây thông Noel", "Chuông", "Dây đèn", "Lò sưởi", "Nến", "Ngôi sao", "Người tuyết", "Ông già Noel", "Ống khói", "Quà giáng sinh", "Quả châu", "Ruy băng", "Thiệp giáng sinh", "Tuần lộc", "Vòng nguyệt quế Giáng sinh", "Xe trượt tuyết"],
	},
	{
		"id": "disaster",
		"title": "Thiên tai",
		"context": "hiện tượng tự nhiên cực đoan gây thiệt hại lớn",
		"words": ["Bão", "Bão cát", "Bão tuyết", "Cháy rừng", "Dịch bệnh", "Động đất", "Hạn hán", "Hố sụt", "Lốc xoáy", "Lở đất", "Lũ lụt", "Mưa đá", "Nạn đói", "Phun trào núi lửa", "Sa mạc hóa", "Sóng thần", "Tuyết lở"],
	},
	{
		"id": "wedding",
		"title": "Đám cưới",
		"context": "nghi lễ hôn nhân, gia đình và tiệc mừng đôi lứa",
		"words": ["Hôn lễ", "Chú rể", "Cô dâu", "Nhà trai", "Nhà gái", "Phù dâu", "Phù rể", "Chủ hôn", "Giấy đăng ký kết hôn", "Đám hỏi", "Hủy hôn", "Rước dâu", "Trao nhẫn", "Xe hoa", "Thiệp mời", "Tiệc cưới", "Của hồi môn", "Nhẫn cưới", "Váy cưới", "Bó hoa cưới", "Bánh cưới", "Trầu cau", "Rượu sâm banh", "Quà cưới", "Tiền mừng cưới", "Tuần trăng mật"],
	},
	{
		"id": "ocean",
		"title": "Đại dương",
		"context": "biển cả, sinh vật nước mặn và hoạt động ven bờ",
		"words": ["Biển", "Bãi biển", "Bờ biển", "Vịnh", "Eo biển", "Đảo", "Mũi đất", "Rạn san hô", "Sóng", "Cát", "Thủy triều", "Cảng biển", "Hải đăng", "Khu nghỉ dưỡng", "Tàu ngầm", "Du thuyền", "Thuyền buồm", "Ca nô", "Thợ lặn", "Người cứu hộ ở biển", "Phao cứu hộ", "Thuyền cứu hộ", "Áo phao", "Chân vịt", "Kem chống nắng", "Đồ bơi", "Cá voi", "Cá mập", "Cá heo", "Cá ngựa", "Hải cẩu", "Sứa", "Mực", "Bạch tuộc", "Con trai", "Sao biển", "Cua", "Ốc", "Sò", "Rùa", "Rong biển", "San hô", "Vỏ sò", "Mòng biển", "Chim hải âu", "Chim yến", "Thái Bình Dương", "Đại Tây Dương", "Ấn Độ Dương", "Bắc Băng Dương"],
	},
	{
		"id": "medical_tool",
		"title": "Dụng cụ y tế",
		"context": "khám chữa bệnh, sơ cứu và chăm sóc sức khỏe",
		"words": ["Bảng kiểm tra thị lực", "Băng keo cá nhân", "Bông gòn", "Cái cáng", "Cái cân", "Cái nạng", "Cồn", "Dao mổ", "Hộp cứu thương", "Kéo y tế", "Khẩu trang y tế", "Ống nghe", "Ống tiêm", "Máy đo huyết áp", "Máy sốc điện", "Mặt nạ ôxi", "Nhiệt kế", "Que đè lưỡi", "Que thử thai", "Xe lăn"],
	},
	{
		"id": "instrument",
		"title": "Nhạc cụ",
		"context": "âm thanh, biểu diễn và dụng cụ tạo nhạc",
		"words": ["Chũm chọe", "Cồng chiêng", "Đại phong cầm", "Đàn bầu", "Đàn cello", "Đàn đá", "Đàn ghi ta", "Đàn hạc", "Đàn luýt", "Đàn nhị", "Đàn organ", "Đàn phong cầm", "Đàn piano", "Đàn tam thập lục", "Đàn tranh", "Đàn tỳ bà", "Đàn ukulele", "Đàn vi ô lông", "Kèn harmonica", "Kèn saxophone", "Kèn trumpet", "Kèn túi", "Kẻng tam giác", "Mõ", "Mộc cầm", "Phách", "Sáo", "Sênh tiền", "Trống", "Trống lắc tay", "Tù và"],
	},
	{
		"id": "organ",
		"title": "Cơ quan nội tạng",
		"context": "bộ phận bên trong cơ thể và chức năng sống",
		"words": ["Não", "Tuyến giáp", "Khí quản", "Thực quản", "Mạch máu", "Phổi", "Tim", "Gan", "Dạ dày", "Lá lách", "Thận", "Bàng quang", "Túi mật", "Tụy", "Tá tràng", "Trực tràng", "Ruột non", "Ruột già", "Ruột thừa", "Hậu môn"],
	},
	{
		"id": "new_year",
		"title": "Năm mới",
		"context": "ngày tết, phong tục, may mắn và sum họp gia đình",
		"words": ["Tết dương lịch", "Tết Nguyên Đán", "Tất Niên", "Giao thừa", "Chợ hoa", "Hoa đào", "Hoa mai", "Cây nêu", "Cây quất", "Bánh chưng", "Củ kiệu", "Hạt dưa", "Hạt hướng dương", "Mứt", "Dưa hấu", "Mâm ngũ quả", "Tiền lì xì", "Bao lì xì", "Câu đối", "Pháo hoa", "Điều cấm kỵ", "Dọn dẹp nhà cửa", "Lau dọn bàn thờ", "Phóng sinh", "Xông đất", "Xuất hành đầu năm", "Hái lộc", "Chúc tết", "Múa lân", "Tảo mộ", "Ông Công", "Ông Táo"],
	},
	{
		"id": "farm",
		"title": "Nông trại",
		"context": "chăn nuôi, trồng trọt và lao động ở vùng quê",
		"words": ["Nông dân", "Gia súc", "Gia cầm", "Thủy sản", "Nông sản", "Nhà kho", "Nhà kính", "Cánh đồng", "Đồng cỏ", "Cỏ khô", "Cỏ dại", "Máy cắt cỏ", "Máy gặt đập liên hợp", "Máy kéo", "Cái cào", "Cần câu", "Cuốc đất", "Cuốc chim", "Liềm", "Rìu", "Xẻng", "Bình tưới nước", "Hạt giống", "Cái thang", "Bù nhìn", "Hàng rào", "Xe cút kít", "Giếng", "Cối xay gió", "Máng ăn", "Thức ăn cho gia súc", "Chuồng bò", "Chuồng gà", "Chuồng lợn", "Chuồng ngựa", "Trâu", "Bò", "Lợn", "Dê", "Cừu", "Ngựa", "Gà", "Vịt", "Ngỗng"],
	},
	{
		"id": "shape",
		"title": "Hình dáng",
		"context": "hình học, đường nét và dạng khối cơ bản",
		"words": ["Tam giác", "Thang", "Bình hành", "Thoi", "Chữ nhật", "Vuông", "Đa giác", "Tròn", "Elip", "Hộp chữ nhật", "Lập phương", "Chóp", "Nón", "Cầu", "Trụ", "Lăng trụ"],
	},
	{
		"id": "face",
		"title": "Khuôn mặt",
		"context": "bộ phận nhìn thấy trên đầu và biểu cảm con người",
		"words": ["Mặt", "Trán", "Thái dương", "Tóc", "Tai", "Dái tai", "Mắt", "Mí mắt", "Tròng mắt", "Con ngươi", "Lông mày", "Lông mi", "Má", "Mũi", "Miệng", "Môi", "Râu", "Ria", "Cằm", "Quai hàm", "Lúm đồng tiền", "Nốt ruồi"],
	},
	{
		"id": "personality",
		"title": "Tính cách",
		"context": "đặc điểm cư xử, thái độ và khí chất con người",
		"words": ["Bảo thủ", "Bi quan", "Bướng bỉnh", "Cẩn thận", "Cẩu thả", "Cộc cằn", "Cởi mở", "Cứng đầu", "Dễ gần", "Dễ tính", "Dịu dàng", "Dối trá", "Dũng cảm", "Điềm tĩnh", "Hài hước", "Hào phóng", "Hăng hái", "Hậu đậu", "Hiền lành", "Hiếu thắng", "Hòa đồng", "Hung dữ", "Hướng ngoại", "Hướng nội", "Ích kỷ", "Keo kiệt", "Khiêm tốn", "Khó gần", "Kiêu căng", "Kiên nhẫn", "Lạc quan", "Lạnh lùng", "Liều lĩnh", "Lười biếng", "Nghiêm khắc", "Nghiêm túc", "Nhút nhát", "Nóng tính", "Tham lam", "Thẳng thắn", "Thân thiện", "Thật thà", "Tốt bụng", "Trầm tính", "Tử tế", "Tự tin", "Vui vẻ"],
	},
	{
		"id": "drink",
		"title": "Đồ uống",
		"context": "thức uống hằng ngày, pha chế và hương vị",
		"words": ["Bia", "Cà phê", "Cà phê đen", "Cà phê phin", "Cà phê sữa", "Nước cam", "Nước chanh", "Nước dừa", "Nước ép trái cây", "Nước khoáng", "Nước lọc", "Rượu", "Rượu sâm banh", "Rượu vang", "Sinh tố", "Sinh tố cà chua", "Sinh tố dâu", "Sữa", "Sữa bò", "Sữa đậu nành", "Trà", "Trà đá", "Trà sữa", "Trà thảo mộc", "Trà xanh"],
	},
	{
		"id": "love",
		"title": "Tình yêu",
		"context": "cảm xúc, mối quan hệ và chuyện đôi lứa",
		"words": ["Cặp đôi", "Mối tình đầu", "Người yêu", "Bạn trai", "Bạn gái", "Tình địch", "Cảm nắng", "Tương tư", "Yêu thầm", "Yêu đơn phương", "Hẹn hò", "Nắm tay", "Ôm", "Hôn", "Cãi nhau", "Chia tay", "Làm lành", "Tán tỉnh", "Tỏ tình", "Thất tình", "Ngoại tình", "Cắm sừng"],
	},
	{
		"id": "sport",
		"title": "Thể thao",
		"context": "thi đấu, vận động cơ thể và kỹ năng rèn luyện",
		"words": ["Bắn cung", "Bắn súng", "Bida", "Bi sắt", "Bóng bàn", "Bóng bầu dục", "Bóng chày", "Bóng chuyền", "Bóng đá", "Bóng ném", "Bóng rổ", "Bowling", "Bơi lội", "Câu cá", "Cầu lông", "Cờ tướng", "Cờ vua", "Cờ vây", "Cử tạ", "Đá cầu", "Đánh gôn", "Đấm bốc", "Đấu bò", "Đấu vật", "Điền kinh", "Đua mô tô", "Đua ngựa", "Đua thuyền", "Đua xe đạp", "Khiêu vũ", "Khúc côn cầu", "Leo núi", "Lướt sóng", "Ném đĩa", "Ném lao", "Nhảy cầu", "Nhảy dù", "Quần vợt", "Thể dục dụng cụ", "Thể dục nhịp điệu", "Trượt băng", "Trượt tuyết", "Trượt ván", "Võ thuật", "Yoga"],
	},
	{
		"id": "insect",
		"title": "Côn trùng",
		"context": "sinh vật nhỏ, nhiều chân hoặc cánh trong tự nhiên",
		"words": ["Bướm", "Bọ cánh cứng", "Bọ chét", "Bọ hung", "Bọ ngựa", "Bọ rùa", "Châu chấu", "Chuồn chuồn", "Dế", "Đom đóm", "Gián", "Kiến", "Ong", "Mối", "Muỗi", "Nhện", "Rận", "Rệp", "Ruồi", "Ve sầu"],
	},
	{
		"id": "space",
		"title": "Vũ trụ",
		"context": "thiên thể, bầu trời xa và hoạt động ngoài không gian",
		"words": ["Ngôi sao", "Chòm sao", "Hành tinh", "Tiểu hành tinh", "Thiên thạch", "Dải ngân hà", "Hố đen", "Hệ mặt trời", "Mặt Trời", "Sao Thủy", "Sao Kim", "Trái Đất", "Mặt Trăng", "Sao Hỏa", "Sao Mộc", "Sao Thổ", "Sao Thiên Vương", "Sao Hải Vương", "Sao Diêm Vương", "Sao băng", "Sao chổi", "Sao lùn trắng", "Nhật thực", "Nguyệt thực", "Chân không", "Khí quyển", "Quỹ đạo", "Trọng lực", "Tàu con thoi", "Tàu vũ trụ", "Vệ tinh nhân tạo"],
	},
	{
		"id": "school_subject",
		"title": "Môn học",
		"context": "lớp học, kiến thức và lĩnh vực được giảng dạy",
		"words": ["Âm nhạc", "Công nghệ", "Địa lý", "Giáo dục công dân", "Hóa học", "Lịch sử", "Mỹ thuật", "Ngoại ngữ", "Ngữ văn", "Sinh học", "Thể dục", "Thủ công", "Tiếng Anh", "Tin học", "Toán", "Vật lý", "Kinh tế", "Triết học"],
	},
	{
		"id": "music",
		"title": "Âm nhạc",
		"context": "giai điệu, biểu diễn, thể loại và sáng tạo âm thanh",
		"words": ["Bài hát", "Giai điệu", "Giọng hát", "Hòa âm", "Lời bài hát", "Nhạc cụ", "Nhịp điệu", "Nốt nhạc", "Đơn ca", "Song ca", "Tam ca", "Tốp ca", "Ban nhạc", "Ca sĩ", "Dàn nhạc giao hưởng", "Nhà soạn nhạc", "Nhạc sĩ", "Lệch tông", "Nền", "Cổ điển", "Dân ca", "Điện tử", "Hip hop", "Opera", "Phim", "Pop", "Rock", "Trữ tình", "Quốc ca", "Thánh ca", "Hát", "Khiêu vũ", "Nhảy múa", "Nghe nhạc", "Chơi nhạc cụ", "Sáng tác", "Viết nhạc"],
	},
	{
		"id": "movie",
		"title": "Phim ảnh",
		"context": "điện ảnh, thể loại phim và quá trình sản xuất",
		"words": ["Ca nhạc", "Cổ trang", "Hành động", "Hình sự", "Hoạt hình", "Kinh dị", "Phiêu lưu mạo hiểm", "Tài liệu", "Tình cảm", "Trinh thám", "Viễn tưởng", "Võ thuật", "Truyền hình", "Ngắn", "Đạo diễn", "Diễn viên", "Diễn viên chính", "Diễn viên phụ", "Diễn viên quần chúng", "Diễn viên đóng thế", "Diễn viên lồng tiếng", "Biên kịch", "Người quay phim", "Ngôi sao điện ảnh", "Chuyển thể", "Cốt truyện", "Bối cảnh", "Kịch bản", "Cảnh quay", "Kỹ xảo điện ảnh", "Diễn xuất", "Lồng tiếng", "Thuyết minh", "Phụ đề", "Đoạn giới thiệu phim", "Nhạc phim", "Nhạc nền", "Liên hoan phim", "Giải thưởng điện ảnh"],
	},
]

var levels: Array[Dictionary] = []

func build_levels(_board_generator: BoardGenerator) -> Array[Dictionary]:
	if not levels.is_empty():
		return levels
	for raw_theme in THEMES:
		var theme: Dictionary = raw_theme
		var level: Dictionary = _build_level(theme)
		if not level.is_empty():
			levels.append(level)
	return levels

func get_level(index: int) -> Dictionary:
	if index < 0 or index >= levels.size():
		return {}
	var raw_level: Variant = levels[index]
	if typeof(raw_level) != TYPE_DICTIONARY:
		return {}
	var level: Dictionary = raw_level
	return level

func get_topic(index: int) -> Dictionary:
	return get_level(index)

func get_topic_stages(topic_index: int) -> Array[Dictionary]:
	var topic: Dictionary = get_level(topic_index)
	if topic.is_empty():
		return []
	var raw_stages: Variant = topic.get("stages", [])
	if typeof(raw_stages) != TYPE_ARRAY:
		return []
	var result: Array[Dictionary] = []
	for raw_stage in raw_stages:
		if typeof(raw_stage) == TYPE_DICTIONARY:
			result.append(raw_stage)
	return result

func create_stage_level(topic_index: int, stage_index: int, board_generator: BoardGenerator) -> Dictionary:
	var topic: Dictionary = get_level(topic_index)
	if topic.is_empty():
		return {}
	var stages: Array[Dictionary] = get_topic_stages(topic_index)
	if stage_index < 0 or stage_index >= stages.size():
		return {}
	var stage: Dictionary = stages[stage_index]
	var entries: Array[WordEntry] = _get_entries(stage)
	if entries.size() < MIN_STAGE_WORDS:
		return {}
	var level: Dictionary = {
		"id": "%s_stage_%d" % [String(topic["id"]), stage_index + 1],
		"topic_id": String(topic["id"]),
		"stage_index": stage_index,
		"title": String(topic["title"]),
		"difficulty": "Màn %d" % [stage_index + 1],
		"word_count": entries.size(),
		"board_size": BOARD_SIZE,
		"entries": entries,
		"optimized": true,
	}
	var best_board: Dictionary = {}
	var best_placed: Array[Dictionary] = []
	for attempt in range(OPTIMIZE_ATTEMPTS * 2):
		var ordered: Array[WordEntry] = _make_attempt_order(entries, String(level["id"]), attempt)
		var board: Dictionary = board_generator.generate_board(ordered, BOARD_SIZE, BOARD_SIZE)
		var placed: Array[Dictionary] = _get_placed_words(board)
		if placed.size() > best_placed.size():
			best_board = board
			best_placed = placed
		if placed.size() >= MIN_STAGE_WORDS:
			break
	if best_placed.size() < MIN_STAGE_WORDS:
		return {}
	level["entries"] = _entries_from_placed_words(best_placed)
	level["word_count"] = best_placed.size()
	return {"level": level, "board": best_board}

func _build_level(theme: Dictionary) -> Dictionary:
	var entries: Array[WordEntry] = _create_entries(theme)
	if entries.size() < MIN_PLAYABLE_WORDS:
		return {}
	var estimated_count: int = mini(entries.size(), BOARD_SIZE)
	var stages: Array[Dictionary] = _build_topic_stages(String(theme["id"]), entries)
	return {
		"id": String(theme["id"]),
		"title": String(theme["title"]),
		"word_count": estimated_count,
		"board_size": BOARD_SIZE,
		"entries": entries,
		"stages": stages,
	}

func _build_topic_stages(theme_id: String, entries: Array[WordEntry]) -> Array[Dictionary]:
	var stage_count: int = _get_stage_count(entries.size())
	var ordered: Array[WordEntry] = _make_attempt_order(entries, theme_id, 0)
	var buckets: Array = []
	for i in range(stage_count):
		buckets.append([])
	for i in range(ordered.size()):
		buckets[i % stage_count].append(ordered[i])
	var stages: Array[Dictionary] = []
	for stage_index in range(stage_count):
		var stage_entries: Array[WordEntry] = []
		for entry in buckets[stage_index]:
			if entry is WordEntry:
				stage_entries.append(entry)
		if stage_entries.size() < MIN_STAGE_WORDS:
			continue
		stages.append({
			"id": "%s_stage_%d" % [theme_id, stage_index + 1],
			"stage_index": stage_index,
			"title": "Màn %d" % [stage_index + 1],
			"word_count": stage_entries.size(),
			"entries": stage_entries,
		})
	return stages

func _get_stage_count(word_count: int) -> int:
	if word_count >= MIN_STAGE_WORDS * PREFERRED_STAGE_COUNT:
		return PREFERRED_STAGE_COUNT
	if word_count >= MIN_STAGE_WORDS * 2:
		return 2
	return 1

func _get_entries(level: Dictionary) -> Array[WordEntry]:
	var entries: Array[WordEntry] = []
	var raw_entries: Variant = level.get("entries", [])
	if typeof(raw_entries) != TYPE_ARRAY:
		return entries
	for entry in raw_entries:
		if entry is WordEntry:
			entries.append(entry)
	return entries

func _create_entries(theme: Dictionary) -> Array[WordEntry]:
	var entries: Array[WordEntry] = []
	var seen: Dictionary = {}
	var words: Array = []
	var raw_words: Variant = theme.get("words", [])
	if typeof(raw_words) == TYPE_ARRAY:
		words = raw_words
	for raw_word in words:
		var word: String = VietnameseNormalizer.clean_word(String(raw_word))
		var puzzle_word: String = VietnameseNormalizer.compact_word(word)
		if puzzle_word.length() < 3 or puzzle_word.length() > BOARD_SIZE:
			continue
		if seen.has(puzzle_word):
			continue
		seen[puzzle_word] = true
		entries.append(WordEntry.new(word, _make_clue(word, theme)))
	return entries

func _make_clue(word: String, theme: Dictionary) -> String:
	var title: String = String(theme["title"]).to_lower()
	var context: String = String(theme["context"])
	var role: String = _get_clue_role(word, title)
	var override: String = _get_specific_clue(word, title)
	if override != "":
		return override
	var themed_clue: String = _make_theme_specific_clue(word, title, role)
	if themed_clue != "":
		return _make_unique_clue(word, themed_clue)
	return _make_manual_definition_clue(word, title, context, role)

func _make_theme_specific_clue(word: String, title: String, role: String) -> String:
	var clean: String = VietnameseNormalizer.clean_word(word)
	if title == "thời gian":
		return _time_clue(clean)
	if title == "nhà tắm":
		return _bathroom_clue(clean)
	if title == "các kiểu tóc":
		return _hair_clue(clean)
	if title == "trò chơi dân gian":
		return _folk_game_clue(clean)
	if title == "vũ khí":
		return _weapon_clue(clean)
	if title == "trung thu":
		return _festival_clue(clean, "Trung thu")
	if title == "phòng khách":
		return _room_object_clue(clean, "phòng khách")
	if title == "giáng sinh":
		return _festival_clue(clean, "Giáng sinh")
	if title == "thiên tai":
		return _disaster_clue(clean)
	if title == "đám cưới":
		return _wedding_clue(clean)
	if title == "đại dương":
		return _ocean_clue(clean, role)
	if title == "nhạc cụ":
		return _instrument_clue(clean)
	if title == "cơ quan nội tạng":
		return _organ_clue(clean)
	if title == "năm mới":
		return _festival_clue(clean, "Tết")
	if title == "nông trại":
		return _farm_clue(clean, role)
	if title == "hình dáng":
		return _shape_clue(clean)
	if title == "khuôn mặt":
		return _face_clue(clean)
	if title == "tính cách":
		return _personality_clue(clean)
	if title == "đồ uống":
		return _drink_clue(clean)
	if title == "tình yêu":
		return _love_clue(clean)
	if title == "thể thao":
		return _sport_clue(clean)
	if title == "côn trùng":
		return _insect_clue(clean)
	if title == "vũ trụ":
		return _space_clue(clean)
	if title == "môn học":
		return _subject_clue(clean)
	if title == "âm nhạc":
		return _music_clue(clean)
	if title == "phim ảnh":
		return _movie_clue(clean)
	return ""

func _make_manual_definition_clue(word: String, title: String, context: String, role: String) -> String:
	var clean: String = VietnameseNormalizer.clean_word(word)
	var compound_clue: String = _make_compound_definition_clue(clean)
	if compound_clue != "":
		return _make_unique_clue(word, compound_clue)
	var role_text: String = role.to_lower()
	if role_text == "gợi ý" or role_text == "gợi ý ngắn":
		role_text = "khái niệm"
	return _make_unique_clue(word, "%s trong chủ đề %s; nghĩa gắn với %s và được nhận ra qua công dụng hoặc đặc điểm riêng của từ này." % [
		role_text.capitalize(),
		title,
		context,
	])

func _make_unique_clue(word: String, base_clue: String) -> String:
	var clean: String = VietnameseNormalizer.clean_word(word)
	var compact: String = VietnameseNormalizer.compact_word(clean)
	var syllables: PackedStringArray = clean.split(" ", false)
	return "%s Gợi ý riêng: %d tiếng, %d chữ cái." % [
		base_clue,
		syllables.size(),
		compact.length(),
	]

func _make_compound_definition_clue(clean: String) -> String:
	if clean.contains("bàn"):
		return "Đồ có mặt phẳng hoặc khu vực đặt đồ, thường dùng để thao tác, trang điểm, tiếp khách hoặc bày biện."
	if clean.contains("ghế"):
		return "Đồ dùng để ngồi, có thể có lưng tựa, đệm hoặc kiểu dáng phù hợp từng không gian."
	if clean.contains("tủ") or clean.contains("kệ") or clean.contains("ngăn") or clean.contains("rương"):
		return "Đồ dùng để cất, xếp hoặc trưng bày vật dụng cho gọn gàng."
	if clean.contains("đèn") or clean.contains("nến") or clean.contains("dây đèn"):
		return "Vật tạo ánh sáng hoặc dùng để trang trí bằng ánh sáng."
	if clean.contains("máy") or clean.contains("thiết bị"):
		return "Thiết bị hỗ trợ một công việc cụ thể bằng cơ chế điện, cơ học hoặc đo lường."
	if clean.contains("nước"):
		return "Chất lỏng hoặc thức uống dùng để sinh hoạt, làm sạch, uống hoặc pha chế."
	if clean.contains("bánh") or clean.contains("mứt") or clean.contains("hạt") or clean.contains("củ") or clean.contains("dưa"):
		return "Món ăn hoặc nguyên liệu thường xuất hiện trong bữa ăn, dịp lễ hoặc sinh hoạt gia đình."
	if clean.contains("hoa") or clean.contains("cây") or clean.contains("lá"):
		return "Thực vật hoặc vật trang trí có hình dáng, màu sắc hay ý nghĩa biểu tượng riêng."
	if clean.contains("tàu") or clean.contains("thuyền") or clean.contains("xe"):
		return "Phương tiện dùng để di chuyển, vận chuyển hoặc phục vụ một hoạt động chuyên biệt."
	if clean.contains("cá") or clean.contains("chim") or clean.contains("bọ") or clean.contains("ong") or clean.contains("kiến") or clean.contains("muỗi") or clean.contains("ruồi") or clean.contains("nhện"):
		return "Sinh vật được nhận biết qua hình dáng, môi trường sống và tập tính đặc trưng."
	if clean.contains("súng") or clean.contains("đạn") or clean.contains("bom") or clean.contains("mìn") or clean.contains("tên lửa"):
		return "Vũ khí gây sát thương bằng lực nổ, lực phóng hoặc đạn."
	if clean.contains("dao") or clean.contains("kiếm") or clean.contains("đao") or clean.contains("rìu") or clean.contains("giáo") or clean.contains("lao"):
		return "Vũ khí hoặc dụng cụ có lưỡi sắc, thường dùng để chém, đâm hoặc cắt."
	if clean.contains("bóng"):
		return "Môn chơi hoặc vật liên quan đến quả bóng và kỹ năng điều khiển trong thi đấu."
	if clean.contains("cờ"):
		return "Trò chơi dùng bàn, quân hoặc ký hiệu; người chơi cần tính nước đi và chiến thuật."
	if clean.contains("nhảy") or clean.contains("múa") or clean.contains("khiêu vũ"):
		return "Hoạt động dùng chuyển động cơ thể theo nhịp, luật chơi hoặc biểu diễn."
	if clean.contains("đua") or clean.contains("trượt") or clean.contains("leo") or clean.contains("bơi"):
		return "Hoạt động thể thao cần tốc độ, sức bền hoặc kỹ năng di chuyển."
	if clean.contains("đàn") or clean.contains("kèn") or clean.contains("trống") or clean.contains("sáo"):
		return "Nhạc cụ tạo âm thanh bằng dây, hơi, phím, gõ hoặc thân cộng hưởng."
	if clean.contains("nhạc") or clean.contains("hát") or clean.contains("ca") or clean.contains("giai điệu"):
		return "Khái niệm thuộc âm nhạc, liên quan đến âm thanh, giọng hát, nhịp điệu hoặc biểu diễn."
	if clean.contains("diễn viên") or clean.contains("đạo diễn") or clean.contains("biên kịch") or clean.contains("quay phim"):
		return "Vai trò của người tham gia tạo nên một bộ phim hoặc chương trình."
	if clean.contains("phim") or clean.contains("cảnh") or clean.contains("kịch bản") or clean.contains("cốt truyện"):
		return "Thành phần hoặc thể loại thuộc lĩnh vực phim ảnh."
	if clean.contains("sao") or clean.contains("hành tinh") or clean.contains("mặt trăng") or clean.contains("mặt trời"):
		return "Thiên thể hoặc vật thể trong không gian, thường được nghiên cứu trong thiên văn học."
	if clean.contains("não") or clean.contains("tim") or clean.contains("phổi") or clean.contains("gan") or clean.contains("thận") or clean.contains("ruột"):
		return "Bộ phận bên trong cơ thể, đảm nhiệm chức năng sống quan trọng."
	if clean.contains("mắt") or clean.contains("mũi") or clean.contains("miệng") or clean.contains("tai") or clean.contains("môi"):
		return "Bộ phận trên khuôn mặt, liên quan đến giác quan, biểu cảm hoặc giao tiếp."
	if clean.contains("vui") or clean.contains("buồn") or clean.contains("tốt") or clean.contains("xấu"):
		return "Nét tâm trạng hoặc tính cách thể hiện qua cảm xúc và cách cư xử."
	if clean.contains("tình") or clean.contains("yêu") or clean.contains("hôn") or clean.contains("hẹn"):
		return "Khái niệm hoặc hành động trong quan hệ tình cảm giữa con người."
	if clean.contains("giờ") or clean.contains("ngày") or clean.contains("tháng") or clean.contains("năm") or clean.contains("mùa"):
		return "Mốc hoặc đơn vị dùng để xác định thời điểm, lịch trình hoặc chu kỳ."
	if clean.contains("tam giác") or clean.contains("vuông") or clean.contains("tròn") or clean.contains("cầu") or clean.contains("trụ"):
		return "Dạng hình học nhận biết qua cạnh, góc, đường cong hoặc khối trong không gian."
	return ""

func _make_fallback_word_clue(word: String, title: String, role: String) -> String:
	var clean: String = VietnameseNormalizer.clean_word(word)
	var compact: String = VietnameseNormalizer.compact_word(clean)
	var syllables: PackedStringArray = clean.split(" ", false)
	var first_letter: String = compact.substr(0, 1).to_upper()
	var role_text: String = role.to_lower()
	if role_text == "gợi ý" or role_text == "gợi ý ngắn":
		role_text = "khái niệm"
	return "%s thuộc chủ đề %s; đáp án có %d tiếng, %d chữ cái và bắt đầu bằng chữ %s." % [
		role_text.capitalize(),
		title,
		syllables.size(),
		compact.length(),
		first_letter,
	]

func get_clue_for_word(word: String, level_title_or_id: String) -> String:
	var theme: Dictionary = {}
	var needle: String = VietnameseNormalizer.clean_word(level_title_or_id).to_lower()
	for raw_theme in THEMES:
		if typeof(raw_theme) != TYPE_DICTIONARY:
			continue
		var candidate: Dictionary = raw_theme
		var candidate_id: String = String(candidate.get("id", "")).to_lower()
		var candidate_title: String = VietnameseNormalizer.clean_word(String(candidate.get("title", ""))).to_lower()
		if needle == candidate_id or needle == candidate_title:
			theme = candidate
			break
	if theme.is_empty():
		var override: String = _get_specific_clue(word)
		return override if override != "" else ""
	return _make_clue(word, theme)

func _get_specific_clue(word: String, theme_title: String = "") -> String:
	var manual_clue: String = MANUAL_CLUES.get_clue(word, theme_title)
	if manual_clue != "":
		return manual_clue
	var clean: String = VietnameseNormalizer.clean_word(word)
	for key in CLUE_OVERRIDES.keys():
		if VietnameseNormalizer.clean_word(String(key)) == clean:
			return String(CLUE_OVERRIDES[key])
	return ""

func _time_clue(word: String) -> String:
	if _contains_any(word, ["giây", "phút", "giờ"]):
		return "Đơn vị dùng để đo khoảng thời gian ngắn trong ngày."
	if _contains_any(word, ["thứ", "tuần", "tháng", "quý", "năm"]):
		return "Mốc hoặc đơn vị dùng để sắp xếp lịch và kế hoạch."
	if _contains_any(word, ["thập", "thế", "thiên"]):
		return "Khoảng thời gian rất dài, dùng khi nói về lịch sử hoặc nhiều thế hệ."
	return "Một thời điểm trong ngày hoặc trong lịch, thường gợi nhịp sinh hoạt quen thuộc."

func _bathroom_clue(word: String) -> String:
	if _contains_any(word, ["kem", "dầu", "sữa", "xà", "nước"]):
		return "Sản phẩm dùng khi vệ sinh hoặc chăm sóc cơ thể."
	if _contains_any(word, ["bồn", "vòi", "cống"]):
		return "Bộ phận cố định trong nhà tắm, liên quan đến nước và thoát nước."
	return "Vật dụng cá nhân thường đặt trong nhà tắm để làm sạch hoặc chăm sóc cơ thể."

func _hair_clue(word: String) -> String:
	if _contains_any(word, ["nhuộm", "uốn", "cạo", "húi"]):
		return "Cách xử lý hoặc tạo kiểu làm thay đổi hình dáng mái tóc."
	return "Kiểu dáng hoặc trạng thái của tóc, nhận biết qua độ dài, nếp tóc hoặc cách buộc."

func _folk_game_clue(word: String) -> String:
	if word.begins_with("cờ"):
		return "Trò chơi dùng bàn hoặc quân cờ, cần quan sát và tính nước đi."
	if _contains_any(word, ["nhảy", "kéo", "đá", "đấu", "bắn", "đánh"]):
		return "Trò chơi dân gian thiên về vận động, khéo léo hoặc sức bền."
	return "Hoạt động vui chơi quen thuộc, thường chơi theo nhóm trong sinh hoạt cộng đồng."

func _weapon_clue(word: String) -> String:
	if _contains_any(word, ["súng", "đạn", "đại bác", "tên lửa", "ngư lôi"]):
		return "Vũ khí tấn công từ xa, thường liên quan đến đạn, lực phóng hoặc thuốc nổ."
	if _contains_any(word, ["khiên", "giáp"]):
		return "Dụng cụ dùng để che chắn hoặc phòng thủ khi giao chiến."
	return "Vũ khí cầm tay hoặc công cụ gây sát thương trong chiến đấu."

func _festival_clue(word: String, festival_name: String) -> String:
	if _contains_any(word, ["bánh", "mứt", "rượu", "dưa", "hạt"]):
		return "Món ăn hoặc thức uống thường xuất hiện trong dịp %s." % festival_name
	if _contains_any(word, ["đèn", "hoa", "cây", "vòng", "chuông", "nến", "mặt nạ", "câu đối"]):
		return "Đồ trang trí hoặc biểu tượng quen thuộc của dịp %s." % festival_name
	if _contains_any(word, ["múa", "rước", "ngắm", "phá", "chúc", "dọn", "xông", "xuất", "hái", "phóng"]):
		return "Hoạt động hoặc phong tục thường diễn ra trong dịp %s." % festival_name
	return "Nhân vật, biểu tượng hoặc vật gợi không khí lễ hội %s." % festival_name

func _room_object_clue(word: String, room_name: String) -> String:
	if _contains_any(word, ["ghế", "bàn", "kệ", "tủ", "thảm", "màn"]):
		return "Đồ nội thất giúp bố trí và sử dụng không gian %s." % room_name
	if _contains_any(word, ["tivi", "loa", "âm ly", "điều hòa", "quạt"]):
		return "Thiết bị điện tử hoặc điện gia dụng thường dùng trong %s." % room_name
	return "Vật trang trí hoặc đồ dùng giúp căn %s tiện nghi hơn." % room_name

func _disaster_clue(word: String) -> String:
	if _contains_any(word, ["bão", "lốc"]):
		return "Hiện tượng thời tiết mạnh, có gió lớn và dễ gây thiệt hại."
	if _contains_any(word, ["động đất", "sụt", "lở"]):
		return "Tai biến liên quan đến mặt đất, địa hình hoặc chuyển động địa chất."
	if _contains_any(word, ["lũ", "sóng", "mưa"]):
		return "Thiên tai liên quan đến nước, lượng mưa hoặc biển."
	return "Sự kiện tự nhiên hoặc xã hội gây nguy hiểm trên diện rộng."

func _wedding_clue(word: String) -> String:
	if _contains_any(word, ["cô", "chú", "phù", "chủ"]):
		return "Vai trò của một người trong nghi lễ cưới."
	if _contains_any(word, ["nhẫn", "váy", "hoa", "bánh", "thiệp", "xe", "quà", "tiền"]):
		return "Vật phẩm thường xuất hiện trong lễ cưới hoặc tiệc cưới."
	return "Nghi thức, sự kiện hoặc khái niệm gắn với hôn nhân."

func _ocean_clue(word: String, role: String) -> String:
	if role == "Sinh vật":
		return "Sinh vật sống ở biển hoặc vùng ven biển, nhận biết qua hình dáng và môi trường nước mặn."
	if _contains_any(word, ["tàu", "thuyền", "ca nô", "du thuyền"]):
		return "Phương tiện di chuyển hoặc hoạt động trên biển."
	if _contains_any(word, ["phao", "áo phao", "cứu hộ"]):
		return "Vật dụng hoặc vai trò giúp bảo đảm an toàn khi ở biển."
	return "Địa hình, hiện tượng hoặc vật gắn với biển và đại dương."

func _instrument_clue(word: String) -> String:
	if _contains_any(word, ["đàn"]):
		return "Nhạc cụ tạo âm bằng dây, phím hoặc thân đàn."
	if _contains_any(word, ["kèn", "sáo", "tù và"]):
		return "Nhạc cụ tạo âm bằng luồng hơi."
	if _contains_any(word, ["trống", "mõ", "phách", "chũm", "kẻng"]):
		return "Nhạc cụ gõ, tạo nhịp bằng va chạm."
	return "Nhạc cụ dùng để tạo âm thanh trong biểu diễn."

func _organ_clue(word: String) -> String:
	if _contains_any(word, ["tim", "mạch"]):
		return "Bộ phận thuộc hệ tuần hoàn, liên quan đến máu và nhịp sống."
	if _contains_any(word, ["phổi", "khí quản"]):
		return "Bộ phận thuộc hệ hô hấp, liên quan đến việc thở."
	if _contains_any(word, ["dạ", "ruột", "gan", "tụy", "mật"]):
		return "Bộ phận trong hệ tiêu hóa hoặc hỗ trợ tiêu hóa."
	return "Bộ phận bên trong cơ thể, đảm nhiệm một chức năng sống quan trọng."

func _farm_clue(word: String, role: String) -> String:
	if role == "Sinh vật":
		return "Con vật nuôi hoặc sinh vật quen thuộc trong nông trại."
	if _contains_any(word, ["máy", "cào", "cuốc", "liềm", "xẻng", "bình", "cần"]):
		return "Dụng cụ hoặc máy móc hỗ trợ lao động nông nghiệp."
	if _contains_any(word, ["chuồng", "nhà", "kho", "hàng rào", "giếng"]):
		return "Công trình hoặc khu vực phục vụ sản xuất trong nông trại."
	return "Khái niệm, sản phẩm hoặc hoạt động gắn với trồng trọt và chăn nuôi."

func _shape_clue(word: String) -> String:
	if _contains_any(word, ["hộp", "lập", "chóp", "nón", "cầu", "trụ", "lăng"]):
		return "Dạng khối trong không gian ba chiều."
	return "Hình phẳng nhận biết qua cạnh, góc hoặc đường bao."

func _face_clue(word: String) -> String:
	if _contains_any(word, ["lông", "râu", "ria", "tóc"]):
		return "Phần lông hoặc tóc mọc trên khuôn mặt hay vùng đầu."
	if _contains_any(word, ["mắt", "mũi", "miệng", "môi", "tai"]):
		return "Bộ phận giác quan hoặc biểu cảm trên khuôn mặt."
	return "Vùng hoặc đặc điểm nhìn thấy trên khuôn mặt con người."

func _personality_clue(word: String) -> String:
	if _contains_any(word, ["bi quan", "lạc quan", "tự tin", "nhút nhát"]):
		return "Thái độ hoặc cách nhìn nhận của một người trước tình huống."
	if _contains_any(word, ["thân thiện", "dễ gần", "hòa đồng", "tốt bụng", "hào phóng"]):
		return "Nét tính cách tích cực trong cách đối xử với người khác."
	if _contains_any(word, ["tham", "ích", "keo", "dối", "cộc", "nóng"]):
		return "Nét tính cách tiêu cực, dễ gây khó chịu trong giao tiếp."
	return "Đặc điểm thể hiện qua cách cư xử, suy nghĩ hoặc phản ứng của một người."

func _drink_clue(word: String) -> String:
	if _contains_any(word, ["cà phê", "trà"]):
		return "Thức uống pha từ nguyên liệu có hương thơm, thường dùng khi thư giãn hoặc tỉnh táo."
	if _contains_any(word, ["nước"]):
		return "Loại nước uống dùng để giải khát hoặc bổ sung chất lỏng."
	if _contains_any(word, ["sữa", "sinh tố"]):
		return "Thức uống có vị béo hoặc xay từ nguyên liệu dinh dưỡng."
	return "Thức uống có hương vị riêng, dùng trong bữa ăn hoặc dịp giao tiếp."

func _love_clue(word: String) -> String:
	if _contains_any(word, ["bạn", "người", "cặp", "tình địch"]):
		return "Vai trò hoặc mối quan hệ giữa những người trong chuyện tình cảm."
	if _contains_any(word, ["hẹn", "nắm", "ôm", "hôn", "tỏ", "tán", "làm"]):
		return "Hành động thường xuất hiện trong mối quan hệ tình cảm."
	return "Trạng thái cảm xúc hoặc biến cố trong chuyện yêu đương."

func _sport_clue(word: String) -> String:
	if _contains_any(word, ["bóng"]):
		return "Môn thể thao dùng bóng, cần phối hợp tay, chân hoặc đồng đội."
	if _contains_any(word, ["đua", "trượt", "nhảy", "bơi", "leo"]):
		return "Môn thể thao thiên về vận động cơ thể và kỹ năng di chuyển."
	if _contains_any(word, ["cờ", "bida", "bowling"]):
		return "Môn thi đấu cần chiến thuật, độ chính xác hoặc khả năng tính toán."
	return "Môn thể thao hoặc hoạt động rèn luyện thể chất."

func _insect_clue(word: String) -> String:
	if _contains_any(word, ["bướm", "chuồn", "ong", "ruồi", "muỗi"]):
		return "Sinh vật nhỏ có cánh, thường gặp trong tự nhiên hoặc quanh nơi ở."
	if _contains_any(word, ["bọ", "kiến", "mối", "gián", "dế"]):
		return "Sinh vật nhỏ thuộc nhóm côn trùng, thường có nhiều chân."
	return "Sinh vật nhỏ quen thuộc, có thể sống bám, bò hoặc bay."

func _space_clue(word: String) -> String:
	if _contains_any(word, ["sao", "hành tinh", "mặt trời", "mặt trăng", "trái đất"]):
		return "Thiên thể hoặc vật thể lớn xuất hiện trong không gian."
	if _contains_any(word, ["tàu", "vệ tinh"]):
		return "Phương tiện hoặc thiết bị do con người đưa vào không gian."
	return "Hiện tượng, vùng hoặc khái niệm thuộc thiên văn học."

func _subject_clue(word: String) -> String:
	if _contains_any(word, ["toán", "vật lý", "hóa", "sinh", "tin"]):
		return "Môn học thiên về khoa học, tính toán hoặc quy luật tự nhiên."
	if _contains_any(word, ["lịch", "địa", "công dân", "kinh tế", "triết"]):
		return "Môn học tìm hiểu xã hội, tư duy và đời sống con người."
	return "Môn học rèn luyện ngôn ngữ, nghệ thuật, kỹ năng hoặc thể chất."

func _music_clue(word: String) -> String:
	if _contains_any(word, ["ca", "hát", "giọng"]):
		return "Hoạt động hoặc hình thức biểu diễn bằng giọng người."
	if _contains_any(word, ["nhạc", "giai", "nhịp", "nốt", "hòa"]):
		return "Yếu tố cấu thành âm nhạc, liên quan đến âm thanh và tiết tấu."
	return "Thể loại, vai trò hoặc hoạt động trong lĩnh vực âm nhạc."

func _movie_clue(word: String) -> String:
	if _contains_any(word, ["diễn viên", "đạo diễn", "biên kịch", "quay phim"]):
		return "Vai trò của người tham gia sản xuất hoặc thể hiện một bộ phim."
	if _contains_any(word, ["cảnh", "kịch bản", "cốt truyện", "bối cảnh", "phụ đề", "lồng tiếng"]):
		return "Thành phần giúp tạo nên nội dung hoặc cách trình bày của phim."
	return "Thể loại, hoạt động hoặc khái niệm thuộc lĩnh vực phim ảnh."

func _get_clue_role(word: String, theme_title: String) -> String:
	var clean: String = VietnameseNormalizer.clean_word(word)
	if theme_title == "thời gian":
		return "Mốc hoặc đơn vị"
	if theme_title == "tính cách":
		return "Nét cư xử"
	if theme_title == "hình dáng":
		return "Dạng hình học"
	if theme_title == "cơ quan nội tạng":
		return "Bộ phận cơ thể"
	if _starts_with_any(clean, ["ngủ", "ngáp", "ngáy", "nằm", "chơi", "bắn", "bịt", "chọi", "cướp", "đá", "đánh", "đấu", "đếm", "đi", "kéo", "nhảy", "thả", "trốn", "múa", "ngắm", "phá", "rước", "trao", "chúc", "dọn", "lau", "xông", "xuất", "hái", "tán", "tỏ", "cãi", "chia", "làm", "hẹn", "nắm", "ôm", "hôn", "nghe", "sáng", "viết"]):
		return "Hành động"
	if _contains_any(clean, ["cá", "bọ", "chim", "rùa", "cua", "ốc", "sò", "mực", "ong", "muỗi", "kiến", "nhện", "rận", "rệp", "ruồi", "ngựa", "bò", "lợn", "dê", "cừu", "gà", "vịt", "ngỗng", "trâu", "tuần lộc"]):
		return "Sinh vật"
	if _contains_any(clean, ["máy", "tivi", "âm ly", "điều khiển", "điều hòa", "loa"]):
		return "Thiết bị"
	if _contains_any(clean, ["bàn", "ghế", "tủ", "giường", "kệ", "rương", "gương", "đệm", "gối", "chăn", "khăn", "lược", "bàn chải", "đèn", "quạt", "thảm", "màn cửa", "bình", "cốc", "chai", "ống", "dao", "kiếm", "súng", "bom", "nỏ", "cung", "khiên", "rìu", "roi", "bánh", "hoa", "quà", "thiệp"]):
		return "Vật dụng"
	var compact_length: int = VietnameseNormalizer.compact_word(word).length()
	if compact_length <= 4:
		return "Gợi ý ngắn"
	return "Gợi ý"

func _starts_with_any(text: String, prefixes: Array[String]) -> bool:
	for prefix in prefixes:
		if text.begins_with(prefix):
			return true
	return false

func _contains_any(text: String, needles: Array[String]) -> bool:
	for needle in needles:
		if text.contains(needle):
			return true
	return false

func _make_attempt_order(entries: Array[WordEntry], theme_id: String, attempt: int) -> Array[WordEntry]:
	var ordered: Array[WordEntry] = entries.duplicate()
	if attempt == 0:
		ordered.sort_custom(Callable(self, "_sort_by_length_desc"))
		return ordered
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = _stable_seed(theme_id, attempt)
	for i in range(ordered.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var temp: WordEntry = ordered[i]
		ordered[i] = ordered[j]
		ordered[j] = temp
	return ordered

func _sort_by_length_desc(a: WordEntry, b: WordEntry) -> bool:
	if a.length == b.length:
		return a.word < b.word
	return a.length > b.length

func _entries_from_placed_words(placed: Array[Dictionary]) -> Array[WordEntry]:
	var entries: Array[WordEntry] = []
	for word_data in placed:
		var entry: WordEntry = word_data["entry"]
		entries.append(entry)
	return entries

func _get_placed_words(board: Dictionary) -> Array[Dictionary]:
	var placed: Array[Dictionary] = []
	var raw_placed: Variant = board.get("placed_words", [])
	if typeof(raw_placed) != TYPE_ARRAY:
		return placed
	for word_data in raw_placed:
		if typeof(word_data) == TYPE_DICTIONARY:
			var placed_word: Dictionary = word_data
			placed.append(placed_word)
	return placed

func _stable_seed(text: String, attempt: int) -> int:
	var seed_value: int = 146959810
	for ch in text:
		seed_value = int((seed_value ^ String(ch).unicode_at(0)) * 16777619) & 0x7fffffff
	return seed_value + attempt * 7919
