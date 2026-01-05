class SubwayArrival {
  final String subwayId;
  final String updnLine;
  final String bstatnNm;
  final String statnNm;
  final String arvlMsg2;
  final String arvlMsg3;
  final String barvlDt;
  final String recptnDt;

  final String? btrainNo;

  SubwayArrival({
    required this.subwayId,
    required this.updnLine,
    required this.bstatnNm,
    required this.statnNm,
    required this.arvlMsg2,
    required this.arvlMsg3,
    required this.barvlDt,
    required this.recptnDt,
    this.btrainNo,
  });

  factory SubwayArrival.fromJson(Map<String, dynamic> json) {
    return SubwayArrival(
      subwayId: json['subwayId'] ?? '',
      updnLine: json['updnLine'] ?? '',
      bstatnNm: json['bstatnNm'] ?? '',
      statnNm: json['statnNm'] ?? '',
      arvlMsg2: json['arvlMsg2'] ?? '',
      arvlMsg3: json['arvlMsg3'] ?? '',
      barvlDt: json['barvlDt'] ?? '',
      recptnDt: json['recptnDt'] ?? '',
      btrainNo: json['btrainNo'],
    );
  }
}
