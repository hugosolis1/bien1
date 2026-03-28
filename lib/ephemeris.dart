import 'package:sweph/sweph.dart';

class PlanetData {
  final String name;
  final String nameSpanish;
  final double longitude;
  final String formatted;

  PlanetData({
    required this.name,
    required this.nameSpanish,
    required this.longitude,
    required this.formatted,
  });
}

class AngleData {
  final String name;
  final double longitude;
  final String formatted;

  AngleData({
    required this.name,
    required this.longitude,
    required this.formatted,
  });
}

class EphemerisResult {
  final Map<String, PlanetData> planets;
  final Map<String, AngleData> angles;
  final String datetime;
  final String location;
  final String mode;

  EphemerisResult({
    required this.planets,
    required this.angles,
    required this.datetime,
    required this.location,
    required this.mode,
  });
}

const Map<String, String> planetNamesSpanish = {
  'Sun': 'Sol',
  'Moon': 'Luna',
  'Mercury': 'Mercurio',
  'Venus': 'Venus',
  'Mars': 'Marte',
  'Jupiter': 'Júpiter',
  'Saturn': 'Saturno',
  'Uranus': 'Urano',
  'Neptune': 'Neptuno',
  'Pluto': 'Plutón',
};

const List<String> zodiacSigns = [
  'Aries', 'Tauro', 'Géminis', 'Cáncer', 'Leo', 'Virgo',
  'Libra', 'Escorpio', 'Sagitario', 'Capricornio', 'Acuario', 'Piscis'
];

double normalizeAngle(double angle) {
  angle = angle % 360;
  if (angle < 0) angle += 360;
  return angle;
}

List<dynamic> degreesToSign(double degrees) {
  double normalized = degrees % 360;
  int signIndex = (normalized / 30).floor();
  double degreeInSign = normalized % 30;
  return [zodiacSigns[signIndex], degreeInSign];
}

String formatPosition(double longitude) {
  int degrees = longitude.floor();
  double minutesFull = (longitude - degrees) * 60;
  int minutes = minutesFull.floor();
  double seconds = (minutesFull - minutes) * 60;
  List<dynamic> signInfo = degreesToSign(longitude);
  String sign = signInfo[0];
  return "${degrees.toString().padLeft(3, '0')}°${minutes.toString().padLeft(2, '0')}'${seconds.toStringAsFixed(1)}\" $sign";
}

Future<void> initSweph() async {
  await Sweph.init();
}

EphemerisResult calculatePositions({
  required int year,
  required int month,
  required int day,
  required int hour,
  required int minute,
  required bool heliocentric,
  String ayanamsa = 'lahiri',
}) {
  double jd = Sweph.swe_julday(year, month, day, hour + minute / 60.0, CalendarType.SE_GREG_CAL);

  SwephFlag flags = SwephFlag.SEFLG_SWIEPH | SwephFlag.SEFLG_SPEED;
  
  if (heliocentric) {
    flags = flags | SwephFlag.SEFLG_HELCTR;
  }
  
  flags = flags | SwephFlag.SEFLG_TROPICAL;

  if (ayanamsa == 'lahiri') {
    Sweph.swe_set_sid_mode(SiderealMode.SE_SIDM_LAHIRI, SiderealModeFlag.SE_SIDBIT_NONE, 0.0, 0.0);
  } else if (ayanamsa == 'fagan_bradley') {
    Sweph.swe_set_sid_mode(SiderealMode.SE_SIDM_FAGAN_BRADLEY, SiderealModeFlag.SE_SIDBIT_NONE, 0.0, 0.0);
  } else if (ayanamsa == 'raman') {
    Sweph.swe_set_sid_mode(SiderealMode.SE_SIDM_RAMAN, SiderealModeFlag.SE_SIDBIT_NONE, 0.0, 0.0);
  } else if (ayanamsa == 'krishnamurti') {
    Sweph.swe_set_sid_mode(SiderealMode.SE_SIDM_KRISHNAMURTI, SiderealModeFlag.SE_SIDBIT_NONE, 0.0, 0.0);
  }

  Map<String, PlanetData> planets = {};

  final planetsToCalc = [
    {'name': 'Sol', 'body': HeavenlyBody.SE_SUN},
    {'name': 'Luna', 'body': HeavenlyBody.SE_MOON},
    {'name': 'Mercurio', 'body': HeavenlyBody.SE_MERCURY},
    {'name': 'Venus', 'body': HeavenlyBody.SE_VENUS},
    {'name': 'Marte', 'body': HeavenlyBody.SE_MARS},
    {'name': 'Júpiter', 'body': HeavenlyBody.SE_JUPITER},
    {'name': 'Saturno', 'body': HeavenlyBody.SE_SATURN},
    {'name': 'Urano', 'body': HeavenlyBody.SE_URANUS},
    {'name': 'Neptuno', 'body': HeavenlyBody.SE_NEPTUNE},
    {'name': 'Plutón', 'body': HeavenlyBody.SE_PLUTO},
  ];

  for (var planet in planetsToCalc) {
    try {
      CoordinatesWithSpeed pos = Sweph.swe_calc_ut(jd, planet['body'] as HeavenlyBody, flags);
      double longitude = normalizeAngle(pos.longitude);
      planets[planet['name'] as String] = PlanetData(
        name: planet['name'] as String,
        nameSpanish: planet['name'] as String,
        longitude: longitude,
        formatted: formatPosition(longitude),
      );
    } catch (e) {
      planets[planet['name'] as String] = PlanetData(
        name: planet['name'] as String,
        nameSpanish: planet['name'] as String,
        longitude: 0,
        formatted: 'Error: $e',
      );
    }
  }

  try {
    CoordinatesWithSpeed chironPos = Sweph.swe_calc_ut(jd, HeavenlyBody.SE_CHIRON, flags);
    double chironLon = normalizeAngle(chironPos.longitude);
    planets['Quirón'] = PlanetData(
      name: 'Chiron',
      nameSpanish: 'Quirón',
      longitude: chironLon,
      formatted: formatPosition(chironLon),
    );
  } catch (e) {
    // Quirón no disponible
  }

  Map<String, AngleData> angles = {};

  try {
    double lat = 51.4769;
    double lon = -0.0005;
    
    HouseCuspData houses = Sweph.swe_houses(jd, lat, lon, Hsys.P);
    
    if (houses.cusps.isNotEmpty) {
      double ascLon = normalizeAngle(houses.cusps[0]);
      angles['Ascendente (ASC)'] = AngleData(
        name: 'ASC',
        longitude: ascLon,
        formatted: formatPosition(ascLon),
      );
      
      double mcLon = normalizeAngle(houses.cusps[9]);
      angles['Medium Coeli (MC)'] = AngleData(
        name: 'MC',
        longitude: mcLon,
        formatted: formatPosition(mcLon),
      );
      
      double descLon = normalizeAngle(houses.cusps[0] + 180);
      angles['Descendente (DESC)'] = AngleData(
        name: 'DESC',
        longitude: descLon,
        formatted: formatPosition(descLon),
      );
      
      double icLon = normalizeAngle(houses.cusps[9] + 180);
      angles['Imum Coeli (IC)'] = AngleData(
        name: 'IC',
        longitude: icLon,
        formatted: formatPosition(icLon),
      );
    }
  } catch (e) {
    angles['Note'] = AngleData(
      name: 'Error',
      longitude: 0,
      formatted: 'Error calculando casas: $e',
    );
  }

  String mode = heliocentric ? 'Heliocéntrico' : 'Geocéntrico';

  return EphemerisResult(
    planets: planets,
    angles: angles,
    datetime: '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')} $hour:${minute.toString().padLeft(2, '0')}',
    location: 'Greenwich, Inglaterra (51.48°N, 0.00°W)',
    mode: mode,
  );
}

DateTime? findDegreeCrossing({
  required String planetName,
  required double targetDegree,
  required DateTime startDate,
  bool forward = true,
  int maxDays = 366,
  bool heliocentric = false,
}) {
  SwephFlag flags = SwephFlag.SEFLG_SWIEPH;
  
  if (heliocentric) {
    flags = flags | SwephFlag.SEFLG_HELCTR;
  }
  
  flags = flags | SwephFlag.SEFLG_TROPICAL;

  final planetMap = {
    'Sol': HeavenlyBody.SE_SUN,
    'Luna': HeavenlyBody.SE_MOON,
    'Mercurio': HeavenlyBody.SE_MERCURY,
    'Venus': HeavenlyBody.SE_VENUS,
    'Marte': HeavenlyBody.SE_MARS,
    'Júpiter': HeavenlyBody.SE_JUPITER,
    'Saturno': HeavenlyBody.SE_SATURN,
    'Urano': HeavenlyBody.SE_URANUS,
    'Neptuno': HeavenlyBody.SE_NEPTUNE,
    'Plutón': HeavenlyBody.SE_PLUTO,
  };
  
  var body = planetMap[planetName];
  if (body == null) return null;
  
  int step = forward ? 1 : -1;
  
  DateTime? lastCrossing;
  
  for (int i = 0; i < maxDays; i++) {
    DateTime currentDate = startDate.add(Duration(days: i * step));
    
    double jdCurrent = Sweph.swe_julday(
      currentDate.year, currentDate.month, currentDate.day,
      12.0, CalendarType.SE_GREG_CAL
    );
    
    double jdNext = Sweph.swe_julday(
      currentDate.year, currentDate.month, currentDate.day + step,
      12.0, CalendarType.SE_GREG_CAL
    );
    
    try {
      CoordinatesWithSpeed posCurrent = Sweph.swe_calc_ut(jdCurrent, body, flags);
      CoordinatesWithSpeed posNext = Sweph.swe_calc_ut(jdNext, body, flags);
      
      double lonCurrent = normalizeAngle(posCurrent.longitude);
      double lonNext = normalizeAngle(posNext.longitude);
      
      bool crossed = (lonCurrent < targetDegree && lonNext >= targetDegree) ||
                     (lonCurrent > lonNext && (lonCurrent < targetDegree || lonNext >= targetDegree));
      
      if (crossed) {
        return currentDate;
      }
    } catch (e) {
      continue;
    }
  }
  
  return lastCrossing;
}

double calculateSunLongitude(double jd) {
  SwephFlag flags = SwephFlag.SEFLG_SWIEPH;
  CoordinatesWithSpeed pos = Sweph.swe_calc_ut(jd, HeavenlyBody.SE_SUN, flags);
  return normalizeAngle(pos.longitude);
}

double calculateMoonLongitude(double jd) {
  SwephFlag flags = SwephFlag.SEFLG_SWIEPH;
  CoordinatesWithSpeed pos = Sweph.swe_calc_ut(jd, HeavenlyBody.SE_MOON, flags);
  return normalizeAngle(pos.longitude);
}

double calculateMercuryLongitude(double jd) {
  SwephFlag flags = SwephFlag.SEFLG_SWIEPH;
  CoordinatesWithSpeed pos = Sweph.swe_calc_ut(jd, HeavenlyBody.SE_MERCURY, flags);
  return normalizeAngle(pos.longitude);
}

double calculateVenusLongitude(double jd) {
  SwephFlag flags = SwephFlag.SEFLG_SWIEPH;
  CoordinatesWithSpeed pos = Sweph.swe_calc_ut(jd, HeavenlyBody.SE_VENUS, flags);
  return normalizeAngle(pos.longitude);
}

double calculateMarsLongitude(double jd) {
  SwephFlag flags = SwephFlag.SEFLG_SWIEPH;
  CoordinatesWithSpeed pos = Sweph.swe_calc_ut(jd, HeavenlyBody.SE_MARS, flags);
  return normalizeAngle(pos.longitude);
}

double calculateJupiterLongitude(double jd) {
  SwephFlag flags = SwephFlag.SEFLG_SWIEPH;
  CoordinatesWithSpeed pos = Sweph.swe_calc_ut(jd, HeavenlyBody.SE_JUPITER, flags);
  return normalizeAngle(pos.longitude);
}

double calculateSaturnLongitude(double jd) {
  SwephFlag flags = SwephFlag.SEFLG_SWIEPH;
  CoordinatesWithSpeed pos = Sweph.swe_calc_ut(jd, HeavenlyBody.SE_SATURN, flags);
  return normalizeAngle(pos.longitude);
}

double calculateUranusLongitude(double jd) {
  SwephFlag flags = SwephFlag.SEFLG_SWIEPH;
  CoordinatesWithSpeed pos = Sweph.swe_calc_ut(jd, HeavenlyBody.SE_URANUS, flags);
  return normalizeAngle(pos.longitude);
}

double calculateNeptuneLongitude(double jd) {
  SwephFlag flags = SwephFlag.SEFLG_SWIEPH;
  CoordinatesWithSpeed pos = Sweph.swe_calc_ut(jd, HeavenlyBody.SE_NEPTUNE, flags);
  return normalizeAngle(pos.longitude);
}

double calculatePlutoLongitude(double jd) {
  SwephFlag flags = SwephFlag.SEFLG_SWIEPH;
  CoordinatesWithSpeed pos = Sweph.swe_calc_ut(jd, HeavenlyBody.SE_PLUTO, flags);
  return normalizeAngle(pos.longitude);
}

double dateTimeToJulianDay(int year, int month, int day, int hour, int minute) {
  return Sweph.swe_julday(year, month, day, hour + minute / 60.0, CalendarType.SE_GREG_CAL);
}
