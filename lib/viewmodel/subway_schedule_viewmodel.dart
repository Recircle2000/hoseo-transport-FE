import 'package:get/get.dart';
import '../models/subway_schedule_model.dart';
import '../repository/subway_repository.dart';

class SubwayScheduleViewModel extends GetxController {
  final SubwayRepository _repository = SubwayRepository();

  SubwayScheduleViewModel({String? initialStation}) {
    if (initialStation != null) {
      selectedStation.value = initialStation;
    }
  }

  // Observables
  final RxString selectedStation = '천안'.obs;
  final RxString selectedDayType = '평일'.obs;
  final Rx<SubwaySchedule?> scheduleData = Rx<SubwaySchedule?>(null);
  final RxBool isLoading = true.obs;
  final RxString error = ''.obs;

  final RxBool isUpExpanded = true.obs;
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
    final targetStation = selectedStation.value;
    final targetDayType = selectedDayType.value;
    
    isLoading.value = true;
    error.value = '';
    
    try {
      final schedule = await _repository.fetchSchedule(
        targetStation,
        targetDayType,
      );
      
      // Prevent race condition: only update if the request still matches current selection
      if (selectedStation.value == targetStation && selectedDayType.value == targetDayType) {
        scheduleData.value = schedule;
      }
    } catch (e) {
      print('Error fetching schedule: $e');
      if (selectedStation.value == targetStation && selectedDayType.value == targetDayType) {
        error.value = '시간표를 불러오는데 실패했습니다.';
      }
    } finally {
      if (selectedStation.value == targetStation && selectedDayType.value == targetDayType) {
        isLoading.value = false;
      }
    }
  }
}
