import 'package:get/get.dart';
import '../models/subway_schedule_model.dart';
import '../repository/subway_repository.dart';

class SubwayScheduleViewModel extends GetxController {
  final SubwayRepository _repository = SubwayRepository();

  // Observables
  final RxString selectedStation = '천안'.obs;
  final RxString selectedDayType = '평일'.obs;
  final Rx<SubwaySchedule?> scheduleData = Rx<SubwaySchedule?>(null);
  final RxBool isLoading = true.obs;
  final RxString error = ''.obs;

  final RxBool isUpExpanded = false.obs;
  final RxBool isDownExpanded = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Default to '천안' and '평일' on load
    fetchSchedule();
  }

  void changeStation(String station) {
    if (selectedStation.value != station) {
      selectedStation.value = station;
      fetchSchedule();
    }
  }

  void changeDayType(String dayType) {
    if (selectedDayType.value != dayType) {
      selectedDayType.value = dayType;
      fetchSchedule();
    }
  }

  Future<void> fetchSchedule() async {
    isLoading.value = true;
    error.value = '';
    
    try {
      final schedule = await _repository.fetchSchedule(
        selectedStation.value,
        selectedDayType.value,
      );
      scheduleData.value = schedule;
    } catch (e) {
      print('Error fetching schedule: $e');
      error.value = '시간표를 불러오는데 실패했습니다.';
    } finally {
      isLoading.value = false;
    }
  }
}
