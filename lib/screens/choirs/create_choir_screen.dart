import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/choir_controller.dart';

class CreateChoirScreen extends StatefulWidget {
  const CreateChoirScreen({super.key});

  @override
  State<CreateChoirScreen> createState() => _CreateChoirScreenState();
}

class _CreateChoirScreenState extends State<CreateChoirScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  Uint8List? _webImageBytes;
  
  // Country search functionality
  final TextEditingController _countrySearchController = TextEditingController();
  String? _selectedCountry;
  bool _isCountryDropdownOpen = false;
  
  // Diocese search functionality
  final TextEditingController _dioceseSearchController = TextEditingController();
  String? _selectedDiocese;
  bool _isCustomDiocese = false;
  final TextEditingController _customDioceseController = TextEditingController();
  
  // Parish search functionality
  final TextEditingController _parishSearchController = TextEditingController();
  String? _selectedParish;
  bool _isParishDropdownOpen = false;
  bool _isCustomParish = false;
  final TextEditingController _customParishController = TextEditingController();


  // Countries list with flags
  static const List<Map<String, String>> _countries = [
    {'name': 'Albania', 'flag': '🇦🇱'},
    {'name': 'Algeria', 'flag': '🇩🇿'},
    {'name': 'Andorra', 'flag': '🇦🇩'},
    {'name': 'Angola', 'flag': '🇦🇴'},
    {'name': 'Antigua and Barbuda', 'flag': '🇦🇬'},
    {'name': 'Argentina', 'flag': '🇦🇷'},
    {'name': 'Armenia', 'flag': '🇦🇲'},
    {'name': 'Australia', 'flag': '🇦🇺'},
    {'name': 'Austria', 'flag': '🇦🇹'},
    {'name': 'Bahrain', 'flag': '🇧🇭'},
    {'name': 'Bangladesh', 'flag': '🇧🇩'},
    {'name': 'Barbados', 'flag': '🇧🇧'},
    {'name': 'Belarus', 'flag': '🇧🇾'},
    {'name': 'Belgium', 'flag': '🇧🇪'},
    {'name': 'Belize', 'flag': '🇧🇿'},
    {'name': 'Benin', 'flag': '🇧🇯'},
    {'name': 'Bolivia', 'flag': '🇧🇴'},
    {'name': 'Bosnia and Herzegovina', 'flag': '🇧🇦'},
    {'name': 'Botswana', 'flag': '🇧🇼'},
    {'name': 'Brazil', 'flag': '🇧🇷'},
    {'name': 'Bulgaria', 'flag': '🇧🇬'},
    {'name': 'Burkina Faso', 'flag': '🇧🇫'},
    {'name': 'Burundi', 'flag': '🇧🇮'},
    {'name': 'Cambodia', 'flag': '🇰🇭'},
    {'name': 'Cameroon', 'flag': '🇨🇲'},
    {'name': 'Canada', 'flag': '🇨🇦'},
    {'name': 'Cape Verde', 'flag': '🇨🇻'},
    {'name': 'Central African Republic', 'flag': '🇨🇫'},
    {'name': 'Chad', 'flag': '🇹🇩'},
    {'name': 'Chile', 'flag': '🇨🇱'},
    {'name': 'Colombia', 'flag': '🇨🇴'},
    {'name': 'Comoros', 'flag': '🇰🇲'},
    {'name': 'Congo', 'flag': '🇨🇬'},
    {'name': 'Costa Rica', 'flag': '🇨🇷'},
    {'name': 'Croatia', 'flag': '🇭🇷'},
    {'name': 'Cuba', 'flag': '🇨🇺'},
    {'name': 'Cyprus', 'flag': '🇨🇾'},
    {'name': 'Czech Republic', 'flag': '🇨🇿'},
    {'name': 'Democratic Republic of Congo', 'flag': '🇨🇩'},
    {'name': 'Denmark', 'flag': '🇩🇰'},
    {'name': 'Dominica', 'flag': '🇩🇲'},
    {'name': 'Dominican Republic', 'flag': '🇩🇴'},
    {'name': 'East Timor', 'flag': '🇹🇱'},
    {'name': 'Ecuador', 'flag': '🇪🇨'},
    {'name': 'Egypt', 'flag': '🇪🇬'},
    {'name': 'El Salvador', 'flag': '🇸🇻'},
    {'name': 'Equatorial Guinea', 'flag': '🇬🇶'},
    {'name': 'Eritrea', 'flag': '🇪🇷'},
    {'name': 'Estonia', 'flag': '🇪🇪'},
    {'name': 'Eswatini', 'flag': '🇸🇿'},
    {'name': 'Ethiopia', 'flag': '🇪🇹'},
    {'name': 'Fiji', 'flag': '🇫🇯'},
    {'name': 'Finland', 'flag': '🇫🇮'},
    {'name': 'France', 'flag': '🇫🇷'},
    {'name': 'Gabon', 'flag': '🇬🇦'},
    {'name': 'Gambia', 'flag': '🇬🇲'},
    {'name': 'Georgia', 'flag': '🇬🇪'},
    {'name': 'Germany', 'flag': '🇩🇪'},
    {'name': 'Ghana', 'flag': '🇬🇭'},
    {'name': 'Greece', 'flag': '🇬🇷'},
    {'name': 'Grenada', 'flag': '🇬🇩'},
    {'name': 'Guatemala', 'flag': '🇬🇹'},
    {'name': 'Guinea', 'flag': '🇬🇳'},
    {'name': 'Guinea-Bissau', 'flag': '🇬🇼'},
    {'name': 'Guyana', 'flag': '🇬🇾'},
    {'name': 'Haiti', 'flag': '🇭🇹'},
    {'name': 'Honduras', 'flag': '🇭🇳'},
    {'name': 'Hungary', 'flag': '🇭🇺'},
    {'name': 'Iceland', 'flag': '🇮🇸'},
    {'name': 'India', 'flag': '🇮🇳'},
    {'name': 'Indonesia', 'flag': '🇮🇩'},
    {'name': 'Iran', 'flag': '🇮🇷'},
    {'name': 'Iraq', 'flag': '🇮🇶'},
    {'name': 'Ireland', 'flag': '🇮🇪'},
    {'name': 'Israel', 'flag': '🇮🇱'},
    {'name': 'Italy', 'flag': '🇮🇹'},
    {'name': 'Ivory Coast', 'flag': '🇨🇮'},
    {'name': 'Jamaica', 'flag': '🇯🇲'},
    {'name': 'Japan', 'flag': '🇯🇵'},
    {'name': 'Jordan', 'flag': '🇯🇴'},
    {'name': 'Kazakhstan', 'flag': '🇰🇿'},
    {'name': 'Kenya', 'flag': '🇰🇪'},
    {'name': 'Kiribati', 'flag': '🇰🇮'},
    {'name': 'Kuwait', 'flag': '🇰🇼'},
    {'name': 'Kyrgyzstan', 'flag': '🇰🇬'},
    {'name': 'Laos', 'flag': '🇱🇦'},
    {'name': 'Latvia', 'flag': '🇱🇻'},
    {'name': 'Lebanon', 'flag': '🇱🇧'},
    {'name': 'Lesotho', 'flag': '🇱🇸'},
    {'name': 'Liberia', 'flag': '🇱🇷'},
    {'name': 'Libya', 'flag': '🇱🇾'},
    {'name': 'Liechtenstein', 'flag': '🇱🇮'},
    {'name': 'Lithuania', 'flag': '🇱🇹'},
    {'name': 'Luxembourg', 'flag': '🇱🇺'},
    {'name': 'Madagascar', 'flag': '🇲🇬'},
    {'name': 'Malawi', 'flag': '🇲🇼'},
    {'name': 'Malaysia', 'flag': '🇲🇾'},
    {'name': 'Maldives', 'flag': '🇲🇻'},
    {'name': 'Mali', 'flag': '🇲🇱'},
    {'name': 'Malta', 'flag': '🇲🇹'},
    {'name': 'Marshall Islands', 'flag': '🇲🇭'},
    {'name': 'Mauritania', 'flag': '🇲🇷'},
    {'name': 'Mauritius', 'flag': '🇲🇺'},
    {'name': 'Mexico', 'flag': '🇲🇽'},
    {'name': 'Micronesia', 'flag': '🇫🇲'},
    {'name': 'Moldova', 'flag': '🇲🇩'},
    {'name': 'Monaco', 'flag': '🇲🇨'},
    {'name': 'Mongolia', 'flag': '🇲🇳'},
    {'name': 'Montenegro', 'flag': '🇲🇪'},
    {'name': 'Morocco', 'flag': '🇲🇦'},
    {'name': 'Mozambique', 'flag': '🇲🇿'},
    {'name': 'Myanmar', 'flag': '🇲🇲'},
    {'name': 'Namibia', 'flag': '🇳🇦'},
    {'name': 'Nauru', 'flag': '🇳🇷'},
    {'name': 'Nepal', 'flag': '🇳🇵'},
    {'name': 'Netherlands', 'flag': '🇳🇱'},
    {'name': 'New Zealand', 'flag': '🇳🇿'},
    {'name': 'Nicaragua', 'flag': '🇳🇮'},
    {'name': 'Niger', 'flag': '🇳🇪'},
    {'name': 'Nigeria', 'flag': '🇳🇬'},
    {'name': 'North Korea', 'flag': '🇰🇵'},
    {'name': 'North Macedonia', 'flag': '🇲🇰'},
    {'name': 'Norway', 'flag': '🇳🇴'},
    {'name': 'Oman', 'flag': '🇴🇲'},
    {'name': 'Pakistan', 'flag': '🇵🇰'},
    {'name': 'Palau', 'flag': '🇵🇼'},
    {'name': 'Panama', 'flag': '🇵🇦'},
    {'name': 'Papua New Guinea', 'flag': '🇵🇬'},
    {'name': 'Paraguay', 'flag': '🇵🇾'},
    {'name': 'Peru', 'flag': '🇵🇪'},
    {'name': 'Philippines', 'flag': '🇵🇭'},
    {'name': 'Poland', 'flag': '🇵🇱'},
    {'name': 'Portugal', 'flag': '🇵🇹'},
    {'name': 'Qatar', 'flag': '🇶🇦'},
    {'name': 'Romania', 'flag': '🇷🇴'},
    {'name': 'Russia', 'flag': '🇷🇺'},
    {'name': 'Rwanda', 'flag': '🇷🇼'},
    {'name': 'Saint Kitts and Nevis', 'flag': '🇰🇳'},
    {'name': 'Saint Lucia', 'flag': '🇱🇨'},
    {'name': 'Saint Vincent and the Grenadines', 'flag': '🇻🇨'},
    {'name': 'Samoa', 'flag': '🇼🇸'},
    {'name': 'San Marino', 'flag': '🇸🇲'},
    {'name': 'Sao Tome and Principe', 'flag': '🇸🇹'},
    {'name': 'Saudi Arabia', 'flag': '🇸🇦'},
    {'name': 'Senegal', 'flag': '🇸🇳'},
    {'name': 'Serbia', 'flag': '🇷🇸'},
    {'name': 'Seychelles', 'flag': '🇸🇨'},
    {'name': 'Sierra Leone', 'flag': '🇸🇱'},
    {'name': 'Singapore', 'flag': '🇸🇬'},
    {'name': 'Slovakia', 'flag': '🇸🇰'},
    {'name': 'Slovenia', 'flag': '🇸🇮'},
    {'name': 'Solomon Islands', 'flag': '🇸🇧'},
    {'name': 'Somalia', 'flag': '🇸🇴'},
    {'name': 'South Africa', 'flag': '🇿🇦'},
    {'name': 'South Korea', 'flag': '🇰🇷'},
    {'name': 'South Sudan', 'flag': '🇸🇸'},
    {'name': 'Spain', 'flag': '🇪🇸'},
    {'name': 'Sri Lanka', 'flag': '🇱🇰'},
    {'name': 'Sudan', 'flag': '🇸🇩'},
    {'name': 'Suriname', 'flag': '🇸🇷'},
    {'name': 'Sweden', 'flag': '🇸🇪'},
    {'name': 'Switzerland', 'flag': '🇨🇭'},
    {'name': 'Syria', 'flag': '🇸🇾'},
    {'name': 'Taiwan', 'flag': '🇹🇼'},
    {'name': 'Tajikistan', 'flag': '🇹🇯'},
    {'name': 'Tanzania', 'flag': '🇹🇿'},
    {'name': 'Thailand', 'flag': '🇹🇭'},
    {'name': 'Togo', 'flag': '🇹🇬'},
    {'name': 'Tonga', 'flag': '🇹🇴'},
    {'name': 'Trinidad and Tobago', 'flag': '🇹🇹'},
    {'name': 'Tunisia', 'flag': '🇹🇳'},
    {'name': 'Turkey', 'flag': '🇹🇷'},
    {'name': 'Turkmenistan', 'flag': '🇹🇲'},
    {'name': 'Tuvalu', 'flag': '🇹🇻'},
    {'name': 'Uganda', 'flag': '🇺🇬'},
    {'name': 'Ukraine', 'flag': '🇺🇦'},
    {'name': 'United Arab Emirates', 'flag': '🇦🇪'},
    {'name': 'United Kingdom', 'flag': '🇬🇧'},
    {'name': 'United States', 'flag': '🇺🇸'},
    {'name': 'Uruguay', 'flag': '🇺🇾'},
    {'name': 'Uzbekistan', 'flag': '🇺🇿'},
    {'name': 'Vanuatu', 'flag': '🇻🇺'},
    {'name': 'Vatican City', 'flag': '🇻🇦'},
    {'name': 'Venezuela', 'flag': '🇻🇪'},
    {'name': 'Vietnam', 'flag': '🇻🇳'},
    {'name': 'Yemen', 'flag': '🇾🇪'},
    {'name': 'Zambia', 'flag': '🇿🇲'},
    {'name': 'Zimbabwe', 'flag': '🇿🇼'},
  ];

  // Diocese data by country
  static const Map<String, List<Map<String, String>>> _diocesesByCountry = {
    'United States': [
      {'name': 'Archdiocese of Atlanta', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Baltimore', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Boston', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Chicago', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Cincinnati', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Denver', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Detroit', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Hartford', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Los Angeles', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Miami', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Milwaukee', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of New Orleans', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of New York', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Newark', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Omaha', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Philadelphia', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Portland', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Saint Louis', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Saint Paul and Minneapolis', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of San Antonio', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of San Francisco', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Santa Fe', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Seattle', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Washington', 'type': 'Archdiocese'},
      {'name': 'Diocese of Albany', 'type': 'Diocese'},
      {'name': 'Diocese of Alexandria', 'type': 'Diocese'},
      {'name': 'Diocese of Allentown', 'type': 'Diocese'},
      {'name': 'Diocese of Arlington', 'type': 'Diocese'},
      {'name': 'Diocese of Austin', 'type': 'Diocese'},
      {'name': 'Diocese of Baker', 'type': 'Diocese'},
      {'name': 'Diocese of Baton Rouge', 'type': 'Diocese'},
      {'name': 'Diocese of Birmingham', 'type': 'Diocese'},
      {'name': 'Diocese of Bridgeport', 'type': 'Diocese'},
      {'name': 'Diocese of Brooklyn', 'type': 'Diocese'},
      {'name': 'Diocese of Buffalo', 'type': 'Diocese'},
      {'name': 'Diocese of Charleston', 'type': 'Diocese'},
      {'name': 'Diocese of Cleveland', 'type': 'Diocese'},
      {'name': 'Diocese of Columbus', 'type': 'Diocese'},
      {'name': 'Diocese of Dallas', 'type': 'Diocese'},
      {'name': 'Diocese of Des Moines', 'type': 'Diocese'},
      {'name': 'Diocese of El Paso', 'type': 'Diocese'},
      {'name': 'Diocese of Fort Worth', 'type': 'Diocese'},
      {'name': 'Diocese of Fresno', 'type': 'Diocese'},
      {'name': 'Diocese of Green Bay', 'type': 'Diocese'},
      {'name': 'Diocese of Honolulu', 'type': 'Diocese'},
      {'name': 'Diocese of Houston', 'type': 'Diocese'},
      {'name': 'Diocese of Kansas City', 'type': 'Diocese'},
      {'name': 'Diocese of Las Vegas', 'type': 'Diocese'},
      {'name': 'Diocese of Madison', 'type': 'Diocese'},
      {'name': 'Diocese of Memphis', 'type': 'Diocese'},
      {'name': 'Diocese of Nashville', 'type': 'Diocese'},
      {'name': 'Diocese of Oakland', 'type': 'Diocese'},
      {'name': 'Diocese of Orange', 'type': 'Diocese'},
      {'name': 'Diocese of Orlando', 'type': 'Diocese'},
      {'name': 'Diocese of Phoenix', 'type': 'Diocese'},
      {'name': 'Diocese of Pittsburgh', 'type': 'Diocese'},
      {'name': 'Diocese of Providence', 'type': 'Diocese'},
      {'name': 'Diocese of Richmond', 'type': 'Diocese'},
      {'name': 'Diocese of Rochester', 'type': 'Diocese'},
      {'name': 'Diocese of Sacramento', 'type': 'Diocese'},
      {'name': 'Diocese of Salt Lake City', 'type': 'Diocese'},
      {'name': 'Diocese of San Bernardino', 'type': 'Diocese'},
      {'name': 'Diocese of San Diego', 'type': 'Diocese'},
      {'name': 'Diocese of San Jose', 'type': 'Diocese'},
      {'name': 'Diocese of Spokane', 'type': 'Diocese'},
      {'name': 'Diocese of Springfield', 'type': 'Diocese'},
      {'name': 'Diocese of St. Petersburg', 'type': 'Diocese'},
      {'name': 'Diocese of Syracuse', 'type': 'Diocese'},
      {'name': 'Diocese of Toledo', 'type': 'Diocese'},
      {'name': 'Diocese of Trenton', 'type': 'Diocese'},
      {'name': 'Diocese of Tucson', 'type': 'Diocese'},
      {'name': 'Diocese of Venice', 'type': 'Diocese'},
      {'name': 'Diocese of Worcester', 'type': 'Diocese'},
    ],
    'Canada': [
      {'name': 'Archdiocese of Edmonton', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Gatineau', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Halifax-Yarmouth', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Keewatin-Le Pas', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Kingston', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Moncton', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Montreal', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Ottawa', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Quebec', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Regina', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Rimouski', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Saint Boniface', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Saskatoon', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Sherbrooke', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Toronto', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Vancouver', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Winnipeg', 'type': 'Archdiocese'},
      {'name': 'Diocese of Alexandria-Cornwall', 'type': 'Diocese'},
      {'name': 'Diocese of Amos', 'type': 'Diocese'},
      {'name': 'Diocese of Antigonish', 'type': 'Diocese'},
      {'name': 'Diocese of Bathurst', 'type': 'Diocese'},
      {'name': 'Diocese of Calgary', 'type': 'Diocese'},
      {'name': 'Diocese of Charlottetown', 'type': 'Diocese'},
      {'name': 'Diocese of Chicoutimi', 'type': 'Diocese'},
      {'name': 'Diocese of Hamilton', 'type': 'Diocese'},
      {'name': 'Diocese of Hearst-Moosonee', 'type': 'Diocese'},
      {'name': 'Diocese of Joliette', 'type': 'Diocese'},
      {'name': 'Diocese of Kamloops', 'type': 'Diocese'},
      {'name': 'Diocese of London', 'type': 'Diocese'},
      {'name': 'Diocese of Nelson', 'type': 'Diocese'},
      {'name': 'Diocese of New Westminster', 'type': 'Diocese'},
      {'name': 'Diocese of Nicolet', 'type': 'Diocese'},
      {'name': 'Diocese of Pembroke', 'type': 'Diocese'},
      {'name': 'Diocese of Peterborough', 'type': 'Diocese'},
      {'name': 'Diocese of Prince Albert', 'type': 'Diocese'},
      {'name': 'Diocese of Prince George', 'type': 'Diocese'},
      {'name': 'Diocese of Saint-Hyacinthe', 'type': 'Diocese'},
      {'name': 'Diocese of Saint-Jean-Longueuil', 'type': 'Diocese'},
      {'name': 'Diocese of Saint John', 'type': 'Diocese'},
      {'name': 'Diocese of Sault Sainte Marie', 'type': 'Diocese'},
      {'name': 'Diocese of St. Catharines', 'type': 'Diocese'},
      {'name': 'Diocese of St. Paul', 'type': 'Diocese'},
      {'name': 'Diocese of Thunder Bay', 'type': 'Diocese'},
      {'name': 'Diocese of Timmins', 'type': 'Diocese'},
      {'name': 'Diocese of Trois-Rivières', 'type': 'Diocese'},
      {'name': 'Diocese of Valleyfield', 'type': 'Diocese'},
      {'name': 'Diocese of Victoria', 'type': 'Diocese'},
      {'name': 'Diocese of Whitehorse', 'type': 'Diocese'},
    ],
    'United Kingdom': [
      {'name': 'Archdiocese of Birmingham', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Cardiff', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Liverpool', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Saint Andrews and Edinburgh', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Southwark', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Westminster', 'type': 'Archdiocese'},
      {'name': 'Diocese of Aberdeen', 'type': 'Diocese'},
      {'name': 'Diocese of Argyll and the Isles', 'type': 'Diocese'},
      {'name': 'Diocese of Brentwood', 'type': 'Diocese'},
      {'name': 'Diocese of Clifton', 'type': 'Diocese'},
      {'name': 'Diocese of Dunkeld', 'type': 'Diocese'},
      {'name': 'Diocese of East Anglia', 'type': 'Diocese'},
      {'name': 'Diocese of Galloway', 'type': 'Diocese'},
      {'name': 'Diocese of Hexham and Newcastle', 'type': 'Diocese'},
      {'name': 'Diocese of Lancaster', 'type': 'Diocese'},
      {'name': 'Diocese of Leeds', 'type': 'Diocese'},
      {'name': 'Diocese of Menevia', 'type': 'Diocese'},
      {'name': 'Diocese of Middlesbrough', 'type': 'Diocese'},
      {'name': 'Diocese of Motherwell', 'type': 'Diocese'},
      {'name': 'Diocese of Northampton', 'type': 'Diocese'},
      {'name': 'Diocese of Nottingham', 'type': 'Diocese'},
      {'name': 'Diocese of Paisley', 'type': 'Diocese'},
      {'name': 'Diocese of Plymouth', 'type': 'Diocese'},
      {'name': 'Diocese of Portsmouth', 'type': 'Diocese'},
      {'name': 'Diocese of Salford', 'type': 'Diocese'},
      {'name': 'Diocese of Shrewsbury', 'type': 'Diocese'},
      {'name': 'Diocese of Wrexham', 'type': 'Diocese'},
    ],
    'Australia': [
      {'name': 'Archdiocese of Adelaide', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Brisbane', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Canberra and Goulburn', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Hobart', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Melbourne', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Perth', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Sydney', 'type': 'Archdiocese'},
      {'name': 'Diocese of Armidale', 'type': 'Diocese'},
      {'name': 'Diocese of Ballarat', 'type': 'Diocese'},
      {'name': 'Diocese of Bathurst', 'type': 'Diocese'},
      {'name': 'Diocese of Broome', 'type': 'Diocese'},
      {'name': 'Diocese of Bunbury', 'type': 'Diocese'},
      {'name': 'Diocese of Cairns', 'type': 'Diocese'},
      {'name': 'Diocese of Darwin', 'type': 'Diocese'},
      {'name': 'Diocese of Geraldton', 'type': 'Diocese'},
      {'name': 'Diocese of Lismore', 'type': 'Diocese'},
      {'name': 'Diocese of Maitland-Newcastle', 'type': 'Diocese'},
      {'name': 'Diocese of Parramatta', 'type': 'Diocese'},
      {'name': 'Diocese of Port Pirie', 'type': 'Diocese'},
      {'name': 'Diocese of Rockhampton', 'type': 'Diocese'},
      {'name': 'Diocese of Sale', 'type': 'Diocese'},
      {'name': 'Diocese of Sandhurst', 'type': 'Diocese'},
      {'name': 'Diocese of Toowoomba', 'type': 'Diocese'},
      {'name': 'Diocese of Townsville', 'type': 'Diocese'},
      {'name': 'Diocese of Wagga Wagga', 'type': 'Diocese'},
      {'name': 'Diocese of Wilcannia-Forbes', 'type': 'Diocese'},
      {'name': 'Diocese of Wollongong', 'type': 'Diocese'},
    ],
    'Philippines': [
      {'name': 'Archdiocese of Cagayan de Oro', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Capiz', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Cebu', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Cotabato', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Davao', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Iloilo', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Jaro', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Lingayen-Dagupan', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Manila', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Nueva Segovia', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Ozamis', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Palo', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of San Fernando', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Tuguegarao', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Zamboanga', 'type': 'Archdiocese'},
      {'name': 'Diocese of Antipolo', 'type': 'Diocese'},
      {'name': 'Diocese of Bacolod', 'type': 'Diocese'},
      {'name': 'Diocese of Baguio', 'type': 'Diocese'},
      {'name': 'Diocese of Baler', 'type': 'Diocese'},
      {'name': 'Diocese of Bangued', 'type': 'Diocese'},
      {'name': 'Diocese of Bataan', 'type': 'Diocese'},
      {'name': 'Diocese of Batanes', 'type': 'Diocese'},
      {'name': 'Diocese of Batangas', 'type': 'Diocese'},
      {'name': 'Diocese of Bayombong', 'type': 'Diocese'},
      {'name': 'Diocese of Boac', 'type': 'Diocese'},
      {'name': 'Diocese of Borongan', 'type': 'Diocese'},
      {'name': 'Diocese of Butuan', 'type': 'Diocese'},
      {'name': 'Diocese of Cabanatuan', 'type': 'Diocese'},
      {'name': 'Diocese of Caloocan', 'type': 'Diocese'},
      {'name': 'Diocese of Catarman', 'type': 'Diocese'},
      {'name': 'Diocese of Cubao', 'type': 'Diocese'},
      {'name': 'Diocese of Daet', 'type': 'Diocese'},
      {'name': 'Diocese of Dumaguete', 'type': 'Diocese'},
      {'name': 'Diocese of Gumaca', 'type': 'Diocese'},
      {'name': 'Diocese of Iba', 'type': 'Diocese'},
      {'name': 'Diocese of Imus', 'type': 'Diocese'},
      {'name': 'Diocese of Ipil', 'type': 'Diocese'},
      {'name': 'Diocese of Isabela', 'type': 'Diocese'},
      {'name': 'Diocese of Kalibo', 'type': 'Diocese'},
      {'name': 'Diocese of Kalookan', 'type': 'Diocese'},
      {'name': 'Diocese of Kidapawan', 'type': 'Diocese'},
      {'name': 'Diocese of Laoag', 'type': 'Diocese'},
      {'name': 'Diocese of Las Piñas', 'type': 'Diocese'},
      {'name': 'Diocese of Legazpi', 'type': 'Diocese'},
      {'name': 'Diocese of Libmanan', 'type': 'Diocese'},
      {'name': 'Diocese of Lipa', 'type': 'Diocese'},
      {'name': 'Diocese of Lucena', 'type': 'Diocese'},
      {'name': 'Diocese of Maasin', 'type': 'Diocese'},
      {'name': 'Diocese of Malolos', 'type': 'Diocese'},
      {'name': 'Diocese of Masbate', 'type': 'Diocese'},
      {'name': 'Diocese of Mati', 'type': 'Diocese'},
      {'name': 'Diocese of Novaliches', 'type': 'Diocese'},
      {'name': 'Diocese of Pagadian', 'type': 'Diocese'},
      {'name': 'Diocese of Palawan', 'type': 'Diocese'},
      {'name': 'Diocese of Paranaque', 'type': 'Diocese'},
      {'name': 'Diocese of Pasig', 'type': 'Diocese'},
      {'name': 'Diocese of Romblon', 'type': 'Diocese'},
      {'name': 'Diocese of Roxas', 'type': 'Diocese'},
      {'name': 'Diocese of San Carlos', 'type': 'Diocese'},
      {'name': 'Diocese of San Jose de Antique', 'type': 'Diocese'},
      {'name': 'Diocese of San Pablo', 'type': 'Diocese'},
      {'name': 'Diocese of Sorsogon', 'type': 'Diocese'},
      {'name': 'Diocese of Surigao', 'type': 'Diocese'},
      {'name': 'Diocese of Tagbilaran', 'type': 'Diocese'},
      {'name': 'Diocese of Talibon', 'type': 'Diocese'},
      {'name': 'Diocese of Tandag', 'type': 'Diocese'},
      {'name': 'Diocese of Tarlac', 'type': 'Diocese'},
      {'name': 'Diocese of Urdaneta', 'type': 'Diocese'},
      {'name': 'Diocese of Virac', 'type': 'Diocese'},
    ],
    'Nigeria': [
      {'name': 'Archdiocese of Abuja', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Benin City', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Calabar', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Ibadan', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Jos', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Kaduna', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Lagos', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Onitsha', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Owerri', 'type': 'Archdiocese'},
      {'name': 'Diocese of Abakaliki', 'type': 'Diocese'},
      {'name': 'Diocese of Abeokuta', 'type': 'Diocese'},
      {'name': 'Diocese of Afikpo', 'type': 'Diocese'},
      {'name': 'Diocese of Aguleri', 'type': 'Diocese'},
      {'name': 'Diocese of Ahiara', 'type': 'Diocese'},
      {'name': 'Diocese of Auchi', 'type': 'Diocese'},
      {'name': 'Diocese of Awgu', 'type': 'Diocese'},
      {'name': 'Diocese of Awka', 'type': 'Diocese'},
      {'name': 'Diocese of Bauchi', 'type': 'Diocese'},
      {'name': 'Diocese of Ekiti', 'type': 'Diocese'},
      {'name': 'Diocese of Enugu', 'type': 'Diocese'},
      {'name': 'Diocese of Gboko', 'type': 'Diocese'},
      {'name': 'Diocese of Gombe', 'type': 'Diocese'},
      {'name': 'Diocese of Idah', 'type': 'Diocese'},
      {'name': 'Diocese of Ijebu-Ode', 'type': 'Diocese'},
      {'name': 'Diocese of Ikot Ekpene', 'type': 'Diocese'},
      {'name': 'Diocese of Ilorin', 'type': 'Diocese'},
      {'name': 'Diocese of Issele-Uku', 'type': 'Diocese'},
      {'name': 'Diocese of Jalingo', 'type': 'Diocese'},
      {'name': 'Diocese of Kano', 'type': 'Diocese'},
      {'name': 'Diocese of Katsina', 'type': 'Diocese'},
      {'name': 'Diocese of Kogi', 'type': 'Diocese'},
      {'name': 'Diocese of Kontagora', 'type': 'Diocese'},
      {'name': 'Diocese of Lafia', 'type': 'Diocese'},
      {'name': 'Diocese of Lokoja', 'type': 'Diocese'},
      {'name': 'Diocese of Maiduguri', 'type': 'Diocese'},
      {'name': 'Diocese of Makurdi', 'type': 'Diocese'},
      {'name': 'Diocese of Minna', 'type': 'Diocese'},
      {'name': 'Diocese of Nsukka', 'type': 'Diocese'},
      {'name': 'Diocese of Ogbomoso', 'type': 'Diocese'},
      {'name': 'Diocese of Okigwe', 'type': 'Diocese'},
      {'name': 'Diocese of Ondo', 'type': 'Diocese'},
      {'name': 'Diocese of Orlu', 'type': 'Diocese'},
      {'name': 'Diocese of Osogbo', 'type': 'Diocese'},
      {'name': 'Diocese of Otukpo', 'type': 'Diocese'},
      {'name': 'Diocese of Oturkpo', 'type': 'Diocese'},
      {'name': 'Diocese of Oyo', 'type': 'Diocese'},
      {'name': 'Diocese of Port Harcourt', 'type': 'Diocese'},
      {'name': 'Diocese of Sokoto', 'type': 'Diocese'},
      {'name': 'Diocese of Umuahia', 'type': 'Diocese'},
      {'name': 'Diocese of Uromi', 'type': 'Diocese'},
      {'name': 'Diocese of Uyo', 'type': 'Diocese'},
      {'name': 'Diocese of Warri', 'type': 'Diocese'},
      {'name': 'Diocese of Yola', 'type': 'Diocese'},
    ],
    'Kenya': [
      {'name': 'Archdiocese of Kisumu', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Mombasa', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Nairobi', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Nyeri', 'type': 'Archdiocese'},
      {'name': 'Diocese of Bungoma', 'type': 'Diocese'},
      {'name': 'Diocese of Eldoret', 'type': 'Diocese'},
      {'name': 'Diocese of Embu', 'type': 'Diocese'},
      {'name': 'Diocese of Garissa', 'type': 'Diocese'},
      {'name': 'Diocese of Homa Bay', 'type': 'Diocese'},
      {'name': 'Diocese of Isiolo', 'type': 'Diocese'},
      {'name': 'Diocese of Kakamega', 'type': 'Diocese'},
      {'name': 'Diocese of Kericho', 'type': 'Diocese'},
      {'name': 'Diocese of Kilifi', 'type': 'Diocese'},
      {'name': 'Diocese of Kitale', 'type': 'Diocese'},
      {'name': 'Diocese of Kitui', 'type': 'Diocese'},
      {'name': 'Diocese of Machakos', 'type': 'Diocese'},
      {'name': 'Diocese of Malindi', 'type': 'Diocese'},
      {'name': 'Diocese of Mandera', 'type': 'Diocese'},
      {'name': 'Diocese of Marsabit', 'type': 'Diocese'},
      {'name': 'Diocese of Meru', 'type': 'Diocese'},
      {'name': 'Diocese of Murang\'a', 'type': 'Diocese'},
      {'name': 'Diocese of Nakuru', 'type': 'Diocese'},
      {'name': 'Diocese of Ngong', 'type': 'Diocese'},
    ],
    'Uganda': [
      {'name': 'Archdiocese of Gulu', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Kampala', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Mbarara', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Tororo', 'type': 'Archdiocese'},
      {'name': 'Diocese of Arua', 'type': 'Diocese'},
      {'name': 'Diocese of Fort Portal', 'type': 'Diocese'},
      {'name': 'Diocese of Hoima', 'type': 'Diocese'},
      {'name': 'Diocese of Jinja', 'type': 'Diocese'},
      {'name': 'Diocese of Kabale', 'type': 'Diocese'},
      {'name': 'Diocese of Kasana-Luweero', 'type': 'Diocese'},
      {'name': 'Diocese of Kiyinda-Mityana', 'type': 'Diocese'},
      {'name': 'Diocese of Kotido', 'type': 'Diocese'},
      {'name': 'Diocese of Lira', 'type': 'Diocese'},
      {'name': 'Diocese of Lugazi', 'type': 'Diocese'},
      {'name': 'Diocese of Masaka', 'type': 'Diocese'},
      {'name': 'Diocese of Moroto', 'type': 'Diocese'},
      {'name': 'Diocese of Nebbi', 'type': 'Diocese'},
      {'name': 'Diocese of Soroti', 'type': 'Diocese'},
    ],
    'Tanzania': [
      {'name': 'Archdiocese of Arusha', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Dar-es-Salaam', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Dodoma', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Mbeya', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Mwanza', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Songea', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Tabora', 'type': 'Archdiocese'},
      {'name': 'Diocese of Bukoba', 'type': 'Diocese'},
      {'name': 'Diocese of Geita', 'type': 'Diocese'},
      {'name': 'Diocese of Iringa', 'type': 'Diocese'},
      {'name': 'Diocese of Kahama', 'type': 'Diocese'},
      {'name': 'Diocese of Kigoma', 'type': 'Diocese'},
      {'name': 'Diocese of Kondoa', 'type': 'Diocese'},
      {'name': 'Diocese of Lindi', 'type': 'Diocese'},
      {'name': 'Diocese of Mahenge', 'type': 'Diocese'},
      {'name': 'Diocese of Mbinga', 'type': 'Diocese'},
      {'name': 'Diocese of Morogoro', 'type': 'Diocese'},
      {'name': 'Diocese of Moshi', 'type': 'Diocese'},
      {'name': 'Diocese of Mpanda', 'type': 'Diocese'},
      {'name': 'Diocese of Musoma', 'type': 'Diocese'},
      {'name': 'Diocese of Mtwara', 'type': 'Diocese'},
      {'name': 'Diocese of Njombe', 'type': 'Diocese'},
      {'name': 'Diocese of Peramiho', 'type': 'Diocese'},
      {'name': 'Diocese of Rulenge-Ngara', 'type': 'Diocese'},
      {'name': 'Diocese of Same', 'type': 'Diocese'},
      {'name': 'Diocese of Shinyanga', 'type': 'Diocese'},
      {'name': 'Diocese of Singida', 'type': 'Diocese'},
      {'name': 'Diocese of Sumbawanga', 'type': 'Diocese'},
      {'name': 'Diocese of Tanga', 'type': 'Diocese'},
      {'name': 'Diocese of Zanzibar', 'type': 'Diocese'},
    ],
    'Brazil': [
      {'name': 'Archdiocese of Aparecida', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Belém do Pará', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Belo Horizonte', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Brasília', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Campinas', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Florianópolis', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Fortaleza', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Goiânia', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Londrina', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Maceió', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Manaus', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Mariana', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Natal', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Niterói', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Olinda e Recife', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Paraíba', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Porto Alegre', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Porto Velho', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Ribeirão Preto', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Rio de Janeiro', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Salvador da Bahia', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Santa Maria', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of São Paulo', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of São Salvador da Bahia', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Teresina', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Vitória', 'type': 'Archdiocese'},
      {'name': 'Diocese of Angra', 'type': 'Diocese'},
      {'name': 'Diocese of Anápolis', 'type': 'Diocese'},
      {'name': 'Diocese of Barreiras', 'type': 'Diocese'},
      {'name': 'Diocese of Campos dos Goytacazes', 'type': 'Diocese'},
      {'name': 'Diocese of Caxias do Sul', 'type': 'Diocese'},
      {'name': 'Diocese of Guarapuava', 'type': 'Diocese'},
      {'name': 'Diocese of Juiz de Fora', 'type': 'Diocese'},
      {'name': 'Diocese of Petrópolis', 'type': 'Diocese'},
      {'name': 'Diocese of Santos', 'type': 'Diocese'},
      {'name': 'Diocese of Sorocaba', 'type': 'Diocese'},
    ],
    'Mexico': [
      {'name': 'Archdiocese of Acapulco', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Antequera', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Chihuahua', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Durango', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Guadalajara', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Hermosillo', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of León', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Mexico', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Monterrey', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Morelia', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Puebla de los Ángeles', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of San Luis Potosí', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Tijuana', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Tlalnepantla', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Toluca', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Tuxtla Gutiérrez', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Xalapa', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Yucatán', 'type': 'Archdiocese'},
      {'name': 'Diocese of Aguascalientes', 'type': 'Diocese'},
      {'name': 'Diocese of Campeche', 'type': 'Diocese'},
      {'name': 'Diocese of Ciudad Juárez', 'type': 'Diocese'},
      {'name': 'Diocese of Cuernavaca', 'type': 'Diocese'},
      {'name': 'Diocese of Mazatlán', 'type': 'Diocese'},
      {'name': 'Diocese of Querétaro', 'type': 'Diocese'},
      {'name': 'Diocese of Tampico', 'type': 'Diocese'},
      {'name': 'Diocese of Veracruz', 'type': 'Diocese'},
    ],
    'Argentina': [
      {'name': 'Archdiocese of Bahía Blanca', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Buenos Aires', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Córdoba', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Corrientes', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of La Plata', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Mendoza', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Paraná', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Rosario', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Salta', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of San Juan de Cuyo', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Santa Fe de la Vera Cruz', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Tucumán', 'type': 'Archdiocese'},
      {'name': 'Diocese of Catamarca', 'type': 'Diocese'},
      {'name': 'Diocese of Formosa', 'type': 'Diocese'},
      {'name': 'Diocese of Jujuy', 'type': 'Diocese'},
      {'name': 'Diocese of La Rioja', 'type': 'Diocese'},
      {'name': 'Diocese of Mar del Plata', 'type': 'Diocese'},
      {'name': 'Diocese of Neuquén', 'type': 'Diocese'},
      {'name': 'Diocese of Posadas', 'type': 'Diocese'},
      {'name': 'Diocese of Río Cuarto', 'type': 'Diocese'},
      {'name': 'Diocese of San Carlos de Bariloche', 'type': 'Diocese'},
      {'name': 'Diocese of Santiago del Estero', 'type': 'Diocese'},
      {'name': 'Diocese of Venado Tuerto', 'type': 'Diocese'},
      {'name': 'Diocese of Zárate-Campana', 'type': 'Diocese'},
    ],
    'Colombia': [
      {'name': 'Archdiocese of Barranquilla', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Bogotá', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Bucaramanga', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Cali', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Cartagena', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Ibagué', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Manizales', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Medellín', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Nueva Pamplona', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Popayán', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Santa Fe de Antioquia', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Tunja', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Villavicencio', 'type': 'Archdiocese'},
      {'name': 'Diocese of Apartadó', 'type': 'Diocese'},
      {'name': 'Diocese of Armenia', 'type': 'Diocese'},
      {'name': 'Diocese of Barrancas', 'type': 'Diocese'},
      {'name': 'Diocese of Buga', 'type': 'Diocese'},
      {'name': 'Diocese of Caldas', 'type': 'Diocese'},
      {'name': 'Diocese of Cúcuta', 'type': 'Diocese'},
      {'name': 'Diocese of Girardot', 'type': 'Diocese'},
      {'name': 'Diocese of Magangué', 'type': 'Diocese'},
      {'name': 'Diocese of Montería', 'type': 'Diocese'},
      {'name': 'Diocese of Neiva', 'type': 'Diocese'},
      {'name': 'Diocese of Palmira', 'type': 'Diocese'},
      {'name': 'Diocese of Pereira', 'type': 'Diocese'},
      {'name': 'Diocese of Sincelejo', 'type': 'Diocese'},
      {'name': 'Diocese of Valledupar', 'type': 'Diocese'},
    ],
    'Peru': [
      {'name': 'Archdiocese of Arequipa', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Ayacucho', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Cusco', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Huancayo', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Lima', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Piura', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Trujillo', 'type': 'Archdiocese'},
      {'name': 'Diocese of Abancay', 'type': 'Diocese'},
      {'name': 'Diocese of Cajamarca', 'type': 'Diocese'},
      {'name': 'Diocese of Callao', 'type': 'Diocese'},
      {'name': 'Diocese of Chachapoyas', 'type': 'Diocese'},
      {'name': 'Diocese of Chiclayo', 'type': 'Diocese'},
      {'name': 'Diocese of Chimbote', 'type': 'Diocese'},
      {'name': 'Diocese of Huánuco', 'type': 'Diocese'},
      {'name': 'Diocese of Iquitos', 'type': 'Diocese'},
      {'name': 'Diocese of Lurín', 'type': 'Diocese'},
      {'name': 'Diocese of Pucallpa', 'type': 'Diocese'},
      {'name': 'Diocese of Puno', 'type': 'Diocese'},
      {'name': 'Diocese of Tacna y Moquegua', 'type': 'Diocese'},
      {'name': 'Diocese of Tarma', 'type': 'Diocese'},
    ],
    'Chile': [
      {'name': 'Archdiocese of Antofagasta', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Concepción', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of La Serena', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Puerto Montt', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Santiago de Chile', 'type': 'Archdiocese'},
      {'name': 'Diocese of Arica', 'type': 'Diocese'},
      {'name': 'Diocese of Calama', 'type': 'Diocese'},
      {'name': 'Diocese of Chillán', 'type': 'Diocese'},
      {'name': 'Diocese of Copiapó', 'type': 'Diocese'},
      {'name': 'Diocese of Iquique', 'type': 'Diocese'},
      {'name': 'Diocese of Linares', 'type': 'Diocese'},
      {'name': 'Diocese of Melipilla', 'type': 'Diocese'},
      {'name': 'Diocese of Osorno', 'type': 'Diocese'},
      {'name': 'Diocese of Punta Arenas', 'type': 'Diocese'},
      {'name': 'Diocese of Rancagua', 'type': 'Diocese'},
      {'name': 'Diocese of San Bernardo', 'type': 'Diocese'},
      {'name': 'Diocese of Talca', 'type': 'Diocese'},
      {'name': 'Diocese of Temuco', 'type': 'Diocese'},
      {'name': 'Diocese of Valdivia', 'type': 'Diocese'},
      {'name': 'Diocese of Valparaíso', 'type': 'Diocese'},
      {'name': 'Diocese of Villarrica', 'type': 'Diocese'},
    ],
    'Italy': [
      {'name': 'Archdiocese of Amalfi-Cava de\' Tirreni', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Ancona-Osimo', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Bari-Bitonto', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Bologna', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Catania', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Firenze', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Genova', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Milano', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Napoli', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Palermo', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Perugia-Città della Pieve', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Pisa', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Roma', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Torino', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Venezia', 'type': 'Archdiocese'},
      {'name': 'Diocese of Bergamo', 'type': 'Diocese'},
      {'name': 'Diocese of Brescia', 'type': 'Diocese'},
      {'name': 'Diocese of Como', 'type': 'Diocese'},
      {'name': 'Diocese of Cremona', 'type': 'Diocese'},
      {'name': 'Diocese of Mantova', 'type': 'Diocese'},
      {'name': 'Diocese of Padova', 'type': 'Diocese'},
      {'name': 'Diocese of Parma', 'type': 'Diocese'},
      {'name': 'Diocese of Reggio Emilia-Guastalla', 'type': 'Diocese'},
      {'name': 'Diocese of Rimini', 'type': 'Diocese'},
      {'name': 'Diocese of Verona', 'type': 'Diocese'},
      {'name': 'Diocese of Vicenza', 'type': 'Diocese'},
    ],
    'France': [
      {'name': 'Archdiocese of Aix', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Albi', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Avignon', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Besançon', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Bordeaux', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Bourges', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Cambrai', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Clermont', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Dijon', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Lille', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Lyon', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Marseille', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Montpellier', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Nancy', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Paris', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Poitiers', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Reims', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Rennes', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Rouen', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Sens', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Strasbourg', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Toulouse', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Tours', 'type': 'Archdiocese'},
      {'name': 'Diocese of Amiens', 'type': 'Diocese'},
      {'name': 'Diocese of Angers', 'type': 'Diocese'},
      {'name': 'Diocese of Bayonne', 'type': 'Diocese'},
      {'name': 'Diocese of Belley-Ars', 'type': 'Diocese'},
      {'name': 'Diocese of Blois', 'type': 'Diocese'},
      {'name': 'Diocese of Cahors', 'type': 'Diocese'},
      {'name': 'Diocese of Chartres', 'type': 'Diocese'},
      {'name': 'Diocese of Grenoble-Vienne', 'type': 'Diocese'},
      {'name': 'Diocese of Le Mans', 'type': 'Diocese'},
      {'name': 'Diocese of Limoges', 'type': 'Diocese'},
      {'name': 'Diocese of Metz', 'type': 'Diocese'},
      {'name': 'Diocese of Nice', 'type': 'Diocese'},
      {'name': 'Diocese of Nîmes', 'type': 'Diocese'},
      {'name': 'Diocese of Orléans', 'type': 'Diocese'},
      {'name': 'Diocese of Perpignan-Elne', 'type': 'Diocese'},
      {'name': 'Diocese of Saint-Brieuc', 'type': 'Diocese'},
      {'name': 'Diocese of Vannes', 'type': 'Diocese'},
      {'name': 'Diocese of Versailles', 'type': 'Diocese'},
    ],
    'Germany': [
      {'name': 'Archdiocese of Bamberg', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Berlin', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Freiburg', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Hamburg', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Köln', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of München und Freising', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Paderborn', 'type': 'Archdiocese'},
      {'name': 'Diocese of Aachen', 'type': 'Diocese'},
      {'name': 'Diocese of Augsburg', 'type': 'Diocese'},
      {'name': 'Diocese of Dresden-Meißen', 'type': 'Diocese'},
      {'name': 'Diocese of Eichstätt', 'type': 'Diocese'},
      {'name': 'Diocese of Erfurt', 'type': 'Diocese'},
      {'name': 'Diocese of Essen', 'type': 'Diocese'},
      {'name': 'Diocese of Fulda', 'type': 'Diocese'},
      {'name': 'Diocese of Görlitz', 'type': 'Diocese'},
      {'name': 'Diocese of Hildesheim', 'type': 'Diocese'},
      {'name': 'Diocese of Limburg', 'type': 'Diocese'},
      {'name': 'Diocese of Mainz', 'type': 'Diocese'},
      {'name': 'Diocese of Münster', 'type': 'Diocese'},
      {'name': 'Diocese of Osnabrück', 'type': 'Diocese'},
      {'name': 'Diocese of Passau', 'type': 'Diocese'},
      {'name': 'Diocese of Regensburg', 'type': 'Diocese'},
      {'name': 'Diocese of Rottenburg-Stuttgart', 'type': 'Diocese'},
      {'name': 'Diocese of Speyer', 'type': 'Diocese'},
      {'name': 'Diocese of Trier', 'type': 'Diocese'},
      {'name': 'Diocese of Würzburg', 'type': 'Diocese'},
    ],
    'Spain': [
      {'name': 'Archdiocese of Barcelona', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Burgos', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Granada', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Madrid', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Mérida-Badajoz', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Oviedo', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Pamplona y Tudela', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Santiago de Compostela', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Sevilla', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Tarragona', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Toledo', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Valencia', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Valladolid', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Zaragoza', 'type': 'Archdiocese'},
      {'name': 'Diocese of Albacete', 'type': 'Diocese'},
      {'name': 'Diocese of Almería', 'type': 'Diocese'},
      {'name': 'Diocese of Ávila', 'type': 'Diocese'},
      {'name': 'Diocese of Badajoz', 'type': 'Diocese'},
      {'name': 'Diocese of Bilbao', 'type': 'Diocese'},
      {'name': 'Diocese of Cádiz y Ceuta', 'type': 'Diocese'},
      {'name': 'Diocese of Córdoba', 'type': 'Diocese'},
      {'name': 'Diocese of Cuenca', 'type': 'Diocese'},
      {'name': 'Diocese of Girona', 'type': 'Diocese'},
      {'name': 'Diocese of Jaén', 'type': 'Diocese'},
      {'name': 'Diocese of León', 'type': 'Diocese'},
      {'name': 'Diocese of Lleida', 'type': 'Diocese'},
      {'name': 'Diocese of Lugo', 'type': 'Diocese'},
      {'name': 'Diocese of Málaga', 'type': 'Diocese'},
      {'name': 'Diocese of Ourense', 'type': 'Diocese'},
      {'name': 'Diocese of Palencia', 'type': 'Diocese'},
      {'name': 'Diocese of Salamanca', 'type': 'Diocese'},
      {'name': 'Diocese of Santander', 'type': 'Diocese'},
      {'name': 'Diocese of Segovia', 'type': 'Diocese'},
      {'name': 'Diocese of Teruel y Albarracín', 'type': 'Diocese'},
      {'name': 'Diocese of Vic', 'type': 'Diocese'},
      {'name': 'Diocese of Vitoria', 'type': 'Diocese'},
      {'name': 'Diocese of Zamora', 'type': 'Diocese'},
    ],
    'Poland': [
      {'name': 'Archdiocese of Białystok', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Częstochowa', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Gdańsk', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Gniezno', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Katowice', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Kraków', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Lublin', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Łódź', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Poznań', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Przemyśl', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Szczecin-Kamień', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Warszawa', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Wrocław', 'type': 'Archdiocese'},
      {'name': 'Diocese of Bielsko-Żywiec', 'type': 'Diocese'},
      {'name': 'Diocese of Bydgoszcz', 'type': 'Diocese'},
      {'name': 'Diocese of Elbląg', 'type': 'Diocese'},
      {'name': 'Diocese of Gliwice', 'type': 'Diocese'},
      {'name': 'Diocese of Kalisz', 'type': 'Diocese'},
      {'name': 'Diocese of Kielce', 'type': 'Diocese'},
      {'name': 'Diocese of Legnica', 'type': 'Diocese'},
      {'name': 'Diocese of Opole', 'type': 'Diocese'},
      {'name': 'Diocese of Płock', 'type': 'Diocese'},
      {'name': 'Diocese of Radom', 'type': 'Diocese'},
      {'name': 'Diocese of Rzeszów', 'type': 'Diocese'},
      {'name': 'Diocese of Sosnowiec', 'type': 'Diocese'},
      {'name': 'Diocese of Tarnów', 'type': 'Diocese'},
      {'name': 'Diocese of Toruń', 'type': 'Diocese'},
      {'name': 'Diocese of Włocławek', 'type': 'Diocese'},
    ],
    'India': [
      {'name': 'Archdiocese of Agra', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Bangalore', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Bhopal', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Bombay', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Calcutta', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Changanassery', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Cuttack-Bhubaneswar', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Delhi', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Gandhinagar', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Goa and Daman', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Guwahati', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Hyderabad', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Imphal', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Kottayam', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Madras and Mylapore', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Madurai', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Nagpur', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Pondicherry and Cuddalore', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Ranchi', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Raipur', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Shillong', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Tellicherry', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Thrissur', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Trivandrum', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Verapoly', 'type': 'Archdiocese'},
      {'name': 'Diocese of Agartala', 'type': 'Diocese'},
      {'name': 'Diocese of Ahmedabad', 'type': 'Diocese'},
      {'name': 'Diocese of Aizawl', 'type': 'Diocese'},
      {'name': 'Diocese of Ajmer', 'type': 'Diocese'},
      {'name': 'Diocese of Allahabad', 'type': 'Diocese'},
      {'name': 'Diocese of Ambikapur', 'type': 'Diocese'},
      {'name': 'Diocese of Asansol', 'type': 'Diocese'},
      {'name': 'Diocese of Aurangabad', 'type': 'Diocese'},
      {'name': 'Diocese of Bagdogra', 'type': 'Diocese'},
      {'name': 'Diocese of Balasore', 'type': 'Diocese'},
      {'name': 'Diocese of Bareilly', 'type': 'Diocese'},
      {'name': 'Diocese of Baroda', 'type': 'Diocese'},
      {'name': 'Diocese of Bellary', 'type': 'Diocese'},
      {'name': 'Diocese of Berhampur', 'type': 'Diocese'},
      {'name': 'Diocese of Bilaspur', 'type': 'Diocese'},
      {'name': 'Diocese of Calicut', 'type': 'Diocese'},
      {'name': 'Diocese of Chanda', 'type': 'Diocese'},
      {'name': 'Diocese of Chingleput', 'type': 'Diocese'},
      {'name': 'Diocese of Coimbatore', 'type': 'Diocese'},
      {'name': 'Diocese of Cochin', 'type': 'Diocese'},
      {'name': 'Diocese of Darjeeling', 'type': 'Diocese'},
      {'name': 'Diocese of Dharmapuri', 'type': 'Diocese'},
      {'name': 'Diocese of Dindigul', 'type': 'Diocese'},
      {'name': 'Diocese of Dumka', 'type': 'Diocese'},
      {'name': 'Diocese of Eluru', 'type': 'Diocese'},
      {'name': 'Diocese of Ernakulam-Angamaly', 'type': 'Diocese'},
      {'name': 'Diocese of Faridabad', 'type': 'Diocese'},
      {'name': 'Diocese of Gorakhpur', 'type': 'Diocese'},
      {'name': 'Diocese of Gulbarga', 'type': 'Diocese'},
      {'name': 'Diocese of Hazaribag', 'type': 'Diocese'},
      {'name': 'Diocese of Hosur', 'type': 'Diocese'},
      {'name': 'Diocese of Irinjalakuda', 'type': 'Diocese'},
      {'name': 'Diocese of Jabalpur', 'type': 'Diocese'},
      {'name': 'Diocese of Jagdalpur', 'type': 'Diocese'},
      {'name': 'Diocese of Jaipur', 'type': 'Diocese'},
      {'name': 'Diocese of Jalpaiguri', 'type': 'Diocese'},
      {'name': 'Diocese of Jamshedpur', 'type': 'Diocese'},
      {'name': 'Diocese of Jhansi', 'type': 'Diocese'},
      {'name': 'Diocese of Jodhpur', 'type': 'Diocese'},
      {'name': 'Diocese of Kannur', 'type': 'Diocese'},
      {'name': 'Diocese of Karwar', 'type': 'Diocese'},
      {'name': 'Diocese of Khunti', 'type': 'Diocese'},
      {'name': 'Diocese of Kohima', 'type': 'Diocese'},
      {'name': 'Diocese of Kolhapur', 'type': 'Diocese'},
      {'name': 'Diocese of Krishnagar', 'type': 'Diocese'},
      {'name': 'Diocese of Kumbakonam', 'type': 'Diocese'},
      {'name': 'Diocese of Kurnool', 'type': 'Diocese'},
      {'name': 'Diocese of Latur', 'type': 'Diocese'},
      {'name': 'Diocese of Lucknow', 'type': 'Diocese'},
      {'name': 'Diocese of Ludhiana', 'type': 'Diocese'},
      {'name': 'Diocese of Malda', 'type': 'Diocese'},
      {'name': 'Diocese of Manaanthavady', 'type': 'Diocese'},
      {'name': 'Diocese of Mangalore', 'type': 'Diocese'},
      {'name': 'Diocese of Meerut', 'type': 'Diocese'},
      {'name': 'Diocese of Miao', 'type': 'Diocese'},
      {'name': 'Diocese of Multan', 'type': 'Diocese'},
      {'name': 'Diocese of Muzaffarpur', 'type': 'Diocese'},
      {'name': 'Diocese of Mysore', 'type': 'Diocese'},
      {'name': 'Diocese of Nashik', 'type': 'Diocese'},
      {'name': 'Diocese of Nellore', 'type': 'Diocese'},
      {'name': 'Diocese of Neyyattinkara', 'type': 'Diocese'},
      {'name': 'Diocese of Ootacamund', 'type': 'Diocese'},
      {'name': 'Diocese of Palai', 'type': 'Diocese'},
      {'name': 'Diocese of Palakkad', 'type': 'Diocese'},
      {'name': 'Diocese of Pasighat', 'type': 'Diocese'},
      {'name': 'Diocese of Patna', 'type': 'Diocese'},
      {'name': 'Diocese of Port Blair', 'type': 'Diocese'},
      {'name': 'Diocese of Pune', 'type': 'Diocese'},
      {'name': 'Diocese of Purnea', 'type': 'Diocese'},
      {'name': 'Diocese of Raiganj', 'type': 'Diocese'},
      {'name': 'Diocese of Rajkot', 'type': 'Diocese'},
      {'name': 'Diocese of Rayagada', 'type': 'Diocese'},
      {'name': 'Diocese of Salem', 'type': 'Diocese'},
      {'name': 'Diocese of Sambalpur', 'type': 'Diocese'},
      {'name': 'Diocese of Satna', 'type': 'Diocese'},
      {'name': 'Diocese of Shimla and Chandigarh', 'type': 'Diocese'},
      {'name': 'Diocese of Simla', 'type': 'Diocese'},
      {'name': 'Diocese of Sindhudurg', 'type': 'Diocese'},
      {'name': 'Diocese of Sivagangai', 'type': 'Diocese'},
      {'name': 'Diocese of Sultanpet', 'type': 'Diocese'},
      {'name': 'Diocese of Surat', 'type': 'Diocese'},
      {'name': 'Diocese of Tezpur', 'type': 'Diocese'},
      {'name': 'Diocese of Thamarassery', 'type': 'Diocese'},
      {'name': 'Diocese of Thanjavur', 'type': 'Diocese'},
      {'name': 'Diocese of Tiruchirapalli', 'type': 'Diocese'},
      {'name': 'Diocese of Tirunelveli', 'type': 'Diocese'},
      {'name': 'Diocese of Tiruvannamalai', 'type': 'Diocese'},
      {'name': 'Diocese of Tuticorin', 'type': 'Diocese'},
      {'name': 'Diocese of Udaipur', 'type': 'Diocese'},
      {'name': 'Diocese of Udupi', 'type': 'Diocese'},
      {'name': 'Diocese of Ujjain', 'type': 'Diocese'},
      {'name': 'Diocese of Varanasi', 'type': 'Diocese'},
      {'name': 'Diocese of Vasai', 'type': 'Diocese'},
      {'name': 'Diocese of Vellore', 'type': 'Diocese'},
      {'name': 'Diocese of Vijayawada', 'type': 'Diocese'},
      {'name': 'Diocese of Visakhapatnam', 'type': 'Diocese'},
      {'name': 'Diocese of Warangal', 'type': 'Diocese'},
      {'name': 'Diocese of Yercaud', 'type': 'Diocese'},
    ],
    'Indonesia': [
      {'name': 'Archdiocese of Ende', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Jakarta', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Kupang', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Makassar', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Medan', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Palembang', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Pontianak', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Samarinda', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Semarang', 'type': 'Archdiocese'},
      {'name': 'Diocese of Agats', 'type': 'Diocese'},
      {'name': 'Diocese of Amboina', 'type': 'Diocese'},
      {'name': 'Diocese of Bandung', 'type': 'Diocese'},
      {'name': 'Diocese of Bogor', 'type': 'Diocese'},
      {'name': 'Diocese of Denpasar', 'type': 'Diocese'},
      {'name': 'Diocese of Jayapura', 'type': 'Diocese'},
      {'name': 'Diocese of Malang', 'type': 'Diocese'},
      {'name': 'Diocese of Manado', 'type': 'Diocese'},
      {'name': 'Diocese of Padang', 'type': 'Diocese'},
      {'name': 'Diocese of Purwokerto', 'type': 'Diocese'},
      {'name': 'Diocese of Surabaya', 'type': 'Diocese'},
      {'name': 'Diocese of Tanjungkarang', 'type': 'Diocese'},
      {'name': 'Diocese of Yogyakarta', 'type': 'Diocese'},
    ],
    'South Africa': [
      {'name': 'Archdiocese of Bloemfontein', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Cape Town', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Durban', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Johannesburg', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Pretoria', 'type': 'Archdiocese'},
      {'name': 'Diocese of De Aar', 'type': 'Diocese'},
      {'name': 'Diocese of Dundee', 'type': 'Diocese'},
      {'name': 'Diocese of Eshowe', 'type': 'Diocese'},
      {'name': 'Diocese of Groblersdal', 'type': 'Diocese'},
      {'name': 'Diocese of Keimoes-Upington', 'type': 'Diocese'},
      {'name': 'Diocese of Kimberley', 'type': 'Diocese'},
      {'name': 'Diocese of Klerksdorp', 'type': 'Diocese'},
      {'name': 'Diocese of Kokstad', 'type': 'Diocese'},
      {'name': 'Diocese of Kroonstad', 'type': 'Diocese'},
      {'name': 'Diocese of Mariannhill', 'type': 'Diocese'},
      {'name': 'Diocese of Mthatha', 'type': 'Diocese'},
      {'name': 'Diocese of Musina', 'type': 'Diocese'},
      {'name': 'Diocese of Oudtshoorn', 'type': 'Diocese'},
      {'name': 'Diocese of Port Elizabeth', 'type': 'Diocese'},
      {'name': 'Diocese of Rustenburg', 'type': 'Diocese'},
      {'name': 'Diocese of Tzaneen', 'type': 'Diocese'},
      {'name': 'Diocese of Witbank', 'type': 'Diocese'},
    ],
    'Ireland': [
      {'name': 'Archdiocese of Armagh', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Cashel and Emly', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Dublin', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Tuam', 'type': 'Archdiocese'},
      {'name': 'Diocese of Achonry', 'type': 'Diocese'},
      {'name': 'Diocese of Ardagh and Clonmacnoise', 'type': 'Diocese'},
      {'name': 'Diocese of Clogher', 'type': 'Diocese'},
      {'name': 'Diocese of Clonfert', 'type': 'Diocese'},
      {'name': 'Diocese of Cloyne', 'type': 'Diocese'},
      {'name': 'Diocese of Cork and Ross', 'type': 'Diocese'},
      {'name': 'Diocese of Derry', 'type': 'Diocese'},
      {'name': 'Diocese of Down and Connor', 'type': 'Diocese'},
      {'name': 'Diocese of Dromore', 'type': 'Diocese'},
      {'name': 'Diocese of Elphin', 'type': 'Diocese'},
      {'name': 'Diocese of Ferns', 'type': 'Diocese'},
      {'name': 'Diocese of Galway, Kilmacduagh and Kilfenora', 'type': 'Diocese'},
      {'name': 'Diocese of Kerry', 'type': 'Diocese'},
      {'name': 'Diocese of Kildare and Leighlin', 'type': 'Diocese'},
      {'name': 'Diocese of Killala', 'type': 'Diocese'},
      {'name': 'Diocese of Killaloe', 'type': 'Diocese'},
      {'name': 'Diocese of Kilmore', 'type': 'Diocese'},
      {'name': 'Diocese of Limerick', 'type': 'Diocese'},
      {'name': 'Diocese of Meath', 'type': 'Diocese'},
      {'name': 'Diocese of Ossory', 'type': 'Diocese'},
      {'name': 'Diocese of Raphoe', 'type': 'Diocese'},
      {'name': 'Diocese of Waterford and Lismore', 'type': 'Diocese'},
    ],
    'Portugal': [
      {'name': 'Archdiocese of Braga', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Évora', 'type': 'Archdiocese'},
      {'name': 'Patriarchate of Lisbon', 'type': 'Archdiocese'},
      {'name': 'Diocese of Angra', 'type': 'Diocese'},
      {'name': 'Diocese of Aveiro', 'type': 'Diocese'},
      {'name': 'Diocese of Beja', 'type': 'Diocese'},
      {'name': 'Diocese of Coimbra', 'type': 'Diocese'},
      {'name': 'Diocese of Funchal', 'type': 'Diocese'},
      {'name': 'Diocese of Guarda', 'type': 'Diocese'},
      {'name': 'Diocese of Lamego', 'type': 'Diocese'},
      {'name': 'Diocese of Leiria-Fátima', 'type': 'Diocese'},
      {'name': 'Diocese of Porto', 'type': 'Diocese'},
      {'name': 'Diocese of Santarém', 'type': 'Diocese'},
      {'name': 'Diocese of Setúbal', 'type': 'Diocese'},
      {'name': 'Diocese of Viana do Castelo', 'type': 'Diocese'},
      {'name': 'Diocese of Vila Real', 'type': 'Diocese'},
      {'name': 'Diocese of Viseu', 'type': 'Diocese'},
    ],
    'Venezuela': [
      {'name': 'Archdiocese of Barquisimeto', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Caracas', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Ciudad Bolívar', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Coro', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Cumaná', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Maracaibo', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Mérida', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Valencia', 'type': 'Archdiocese'},
      {'name': 'Diocese of Acarigua-Araure', 'type': 'Diocese'},
      {'name': 'Diocese of Barcelona', 'type': 'Diocese'},
      {'name': 'Diocese of Cabimas', 'type': 'Diocese'},
      {'name': 'Diocese of Carúpano', 'type': 'Diocese'},
      {'name': 'Diocese of Guanare', 'type': 'Diocese'},
      {'name': 'Diocese of Guarenas', 'type': 'Diocese'},
      {'name': 'Diocese of La Guaira', 'type': 'Diocese'},
      {'name': 'Diocese of Los Teques', 'type': 'Diocese'},
      {'name': 'Diocese of Machiques', 'type': 'Diocese'},
      {'name': 'Diocese of Margarita', 'type': 'Diocese'},
      {'name': 'Diocese of Punto Fijo', 'type': 'Diocese'},
      {'name': 'Diocese of San Carlos', 'type': 'Diocese'},
      {'name': 'Diocese of San Cristóbal', 'type': 'Diocese'},
      {'name': 'Diocese of San Fernando de Apure', 'type': 'Diocese'},
      {'name': 'Diocese of Trujillo', 'type': 'Diocese'},
    ],
    'Ecuador': [
      {'name': 'Archdiocese of Cuenca', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Guayaquil', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Portoviejo', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Quito', 'type': 'Archdiocese'},
      {'name': 'Diocese of Ambato', 'type': 'Diocese'},
      {'name': 'Diocese of Babahoyo', 'type': 'Diocese'},
      {'name': 'Diocese of Esmeraldas', 'type': 'Diocese'},
      {'name': 'Diocese of Guaranda', 'type': 'Diocese'},
      {'name': 'Diocese of Ibarra', 'type': 'Diocese'},
      {'name': 'Diocese of Latacunga', 'type': 'Diocese'},
      {'name': 'Diocese of Loja', 'type': 'Diocese'},
      {'name': 'Diocese of Machala', 'type': 'Diocese'},
      {'name': 'Diocese of Riobamba', 'type': 'Diocese'},
      {'name': 'Diocese of San Miguel de Sucumbíos', 'type': 'Diocese'},
      {'name': 'Diocese of Santo Domingo de los Colorados', 'type': 'Diocese'},
      {'name': 'Diocese of Tulcán', 'type': 'Diocese'},
      {'name': 'Vicariate Apostolic of Galápagos', 'type': 'Diocese'},
    ],
    'Bolivia': [
      {'name': 'Archdiocese of Cochabamba', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of La Paz', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Santa Cruz de la Sierra', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Sucre', 'type': 'Archdiocese'},
      {'name': 'Diocese of El Alto', 'type': 'Diocese'},
      {'name': 'Diocese of Oruro', 'type': 'Diocese'},
      {'name': 'Diocese of Potosí', 'type': 'Diocese'},
      {'name': 'Diocese of San Ignacio de Velasco', 'type': 'Diocese'},
      {'name': 'Diocese of Tarija', 'type': 'Diocese'},
      {'name': 'Vicariate Apostolic of Camiri', 'type': 'Diocese'},
      {'name': 'Vicariate Apostolic of Pando', 'type': 'Diocese'},
      {'name': 'Vicariate Apostolic of Reyes', 'type': 'Diocese'},
      {'name': 'Vicariate Apostolic of Ñuflo de Chávez', 'type': 'Diocese'},
    ],
    'Uruguay': [
      {'name': 'Archdiocese of Montevideo', 'type': 'Archdiocese'},
      {'name': 'Diocese of Canelones', 'type': 'Diocese'},
      {'name': 'Diocese of Florida', 'type': 'Diocese'},
      {'name': 'Diocese of Maldonado-Punta del Este', 'type': 'Diocese'},
      {'name': 'Diocese of Melo', 'type': 'Diocese'},
      {'name': 'Diocese of Mercedes', 'type': 'Diocese'},
      {'name': 'Diocese of Rivera', 'type': 'Diocese'},
      {'name': 'Diocese of Salto', 'type': 'Diocese'},
      {'name': 'Diocese of San José de Mayo', 'type': 'Diocese'},
      {'name': 'Diocese of Tacuarembó', 'type': 'Diocese'},
    ],
    'Paraguay': [
      {'name': 'Archdiocese of Asunción', 'type': 'Archdiocese'},
      {'name': 'Diocese of Caacupé', 'type': 'Diocese'},
      {'name': 'Diocese of Carapeguá', 'type': 'Diocese'},
      {'name': 'Diocese of Ciudad del Este', 'type': 'Diocese'},
      {'name': 'Diocese of Concepción', 'type': 'Diocese'},
      {'name': 'Diocese of Coronel Oviedo', 'type': 'Diocese'},
      {'name': 'Diocese of Encarnación', 'type': 'Diocese'},
      {'name': 'Diocese of Pedro Juan Caballero', 'type': 'Diocese'},
      {'name': 'Diocese of San Juan Bautista de las Misiones', 'type': 'Diocese'},
      {'name': 'Diocese of San Lorenzo', 'type': 'Diocese'},
      {'name': 'Diocese of Villarrica del Espíritu Santo', 'type': 'Diocese'},
      {'name': 'Vicariate Apostolic of Chaco Paraguayo', 'type': 'Diocese'},
    ],
    'Guatemala': [
      {'name': 'Archdiocese of Guatemala', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Los Altos Quetzaltenango-Totonicapán', 'type': 'Archdiocese'},
      {'name': 'Diocese of Cobán', 'type': 'Diocese'},
      {'name': 'Diocese of Escuintla', 'type': 'Diocese'},
      {'name': 'Diocese of Huehuetenango', 'type': 'Diocese'},
      {'name': 'Diocese of Jalapa', 'type': 'Diocese'},
      {'name': 'Diocese of Puerto Barrios', 'type': 'Diocese'},
      {'name': 'Diocese of San Marcos', 'type': 'Diocese'},
      {'name': 'Diocese of Santa Rosa de Lima', 'type': 'Diocese'},
      {'name': 'Diocese of Sololá-Chimaltenango', 'type': 'Diocese'},
      {'name': 'Diocese of Verapaz', 'type': 'Diocese'},
      {'name': 'Diocese of Zacapa y Santo Cristo de Esquipulas', 'type': 'Diocese'},
      {'name': 'Vicariate Apostolic of El Petén', 'type': 'Diocese'},
    ],
    'Costa Rica': [
      {'name': 'Archdiocese of San José de Costa Rica', 'type': 'Archdiocese'},
      {'name': 'Diocese of Alajuela', 'type': 'Diocese'},
      {'name': 'Diocese of Cartago', 'type': 'Diocese'},
      {'name': 'Diocese of Ciudad Quesada', 'type': 'Diocese'},
      {'name': 'Diocese of Limón', 'type': 'Diocese'},
      {'name': 'Diocese of Puntarenas', 'type': 'Diocese'},
      {'name': 'Diocese of Tilarán', 'type': 'Diocese'},
    ],
    'Panama': [
      {'name': 'Archdiocese of Panamá', 'type': 'Archdiocese'},
      {'name': 'Diocese of Chitré', 'type': 'Diocese'},
      {'name': 'Diocese of Colón-Kuna Yala', 'type': 'Diocese'},
      {'name': 'Diocese of David', 'type': 'Diocese'},
      {'name': 'Diocese of Penonomé', 'type': 'Diocese'},
      {'name': 'Diocese of Santiago de Veraguas', 'type': 'Diocese'},
    ],
    'Cuba': [
      {'name': 'Archdiocese of Camagüey', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of San Cristóbal de la Habana', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Santiago de Cuba', 'type': 'Archdiocese'},
      {'name': 'Diocese of Bayamo-Manzanillo', 'type': 'Diocese'},
      {'name': 'Diocese of Cienfuegos', 'type': 'Diocese'},
      {'name': 'Diocese of Holguín', 'type': 'Diocese'},
      {'name': 'Diocese of Matanzas', 'type': 'Diocese'},
      {'name': 'Diocese of Pinar del Río', 'type': 'Diocese'},
      {'name': 'Diocese of Santa Clara', 'type': 'Diocese'},
    ],
    'Dominican Republic': [
      {'name': 'Archdiocese of Santo Domingo', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Santiago de los Caballeros', 'type': 'Archdiocese'},
      {'name': 'Diocese of Baní', 'type': 'Diocese'},
      {'name': 'Diocese of Barahona', 'type': 'Diocese'},
      {'name': 'Diocese of La Vega', 'type': 'Diocese'},
      {'name': 'Diocese of Mao-Monte Cristi', 'type': 'Diocese'},
      {'name': 'Diocese of Nuestra Señora de la Altagracia en Higüey', 'type': 'Diocese'},
      {'name': 'Diocese of Puerto Plata', 'type': 'Diocese'},
      {'name': 'Diocese of San Francisco de Macorís', 'type': 'Diocese'},
      {'name': 'Diocese of San Juan de la Maguana', 'type': 'Diocese'},
      {'name': 'Diocese of San Pedro de Macorís', 'type': 'Diocese'},
    ],
    'Jamaica': [
      {'name': 'Archdiocese of Kingston in Jamaica', 'type': 'Archdiocese'},
      {'name': 'Diocese of Mandeville', 'type': 'Diocese'},
      {'name': 'Diocese of Montego Bay', 'type': 'Diocese'},
    ],
    'Haiti': [
      {'name': 'Archdiocese of Port-au-Prince', 'type': 'Archdiocese'},
      {'name': 'Diocese of Anse-à-Veau et Miragoâne', 'type': 'Diocese'},
      {'name': 'Diocese of Cayes', 'type': 'Diocese'},
      {'name': 'Diocese of Fort-Liberté', 'type': 'Diocese'},
      {'name': 'Diocese of Gonaïves', 'type': 'Diocese'},
      {'name': 'Diocese of Hinche', 'type': 'Diocese'},
      {'name': 'Diocese of Jacmel', 'type': 'Diocese'},
      {'name': 'Diocese of Jérémie', 'type': 'Diocese'},
      {'name': 'Diocese of Port-de-Paix', 'type': 'Diocese'},
    ],
    'Trinidad and Tobago': [
      {'name': 'Archdiocese of Port of Spain', 'type': 'Archdiocese'},
    ],
    'Barbados': [
      {'name': 'Diocese of Bridgetown', 'type': 'Diocese'},
    ],
    'Saint Lucia': [
      {'name': 'Diocese of Castries', 'type': 'Diocese'},
    ],
    'Grenada': [
      {'name': 'Diocese of Saint George\'s in Grenada', 'type': 'Diocese'},
    ],
    'Saint Vincent and the Grenadines': [
      {'name': 'Diocese of Kingstown', 'type': 'Diocese'},
    ],
    'Dominica': [
      {'name': 'Diocese of Roseau', 'type': 'Diocese'},
    ],
    'Antigua and Barbuda': [
      {'name': 'Diocese of Saint John\'s-Basseterre', 'type': 'Diocese'},
    ],
    'Saint Kitts and Nevis': [
      {'name': 'Diocese of Saint John\'s-Basseterre', 'type': 'Diocese'},
    ],
    'Bahamas': [
      {'name': 'Archdiocese of Nassau', 'type': 'Archdiocese'},
    ],
    'Belize': [
      {'name': 'Diocese of Belize City-Belmopan', 'type': 'Diocese'},
    ],
    'Honduras': [
      {'name': 'Archdiocese of Tegucigalpa', 'type': 'Archdiocese'},
      {'name': 'Diocese of Choluteca', 'type': 'Diocese'},
      {'name': 'Diocese of Comayagua', 'type': 'Diocese'},
      {'name': 'Diocese of Danlí', 'type': 'Diocese'},
      {'name': 'Diocese of La Ceiba', 'type': 'Diocese'},
      {'name': 'Diocese of San Pedro Sula', 'type': 'Diocese'},
      {'name': 'Diocese of Santa Rosa de Copán', 'type': 'Diocese'},
      {'name': 'Diocese of Trujillo', 'type': 'Diocese'},
    ],
    'El Salvador': [
      {'name': 'Archdiocese of San Salvador', 'type': 'Archdiocese'},
      {'name': 'Diocese of Chalatenango', 'type': 'Diocese'},
      {'name': 'Diocese of San Miguel', 'type': 'Diocese'},
      {'name': 'Diocese of San Vicente', 'type': 'Diocese'},
      {'name': 'Diocese of Santa Ana', 'type': 'Diocese'},
      {'name': 'Diocese of Santiago de María', 'type': 'Diocese'},
      {'name': 'Diocese of Sonsonate', 'type': 'Diocese'},
      {'name': 'Diocese of Zacatecoluca', 'type': 'Diocese'},
    ],
    'Nicaragua': [
      {'name': 'Archdiocese of Managua', 'type': 'Archdiocese'},
      {'name': 'Diocese of Bluefields', 'type': 'Diocese'},
      {'name': 'Diocese of Estelí', 'type': 'Diocese'},
      {'name': 'Diocese of Granada', 'type': 'Diocese'},
      {'name': 'Diocese of Jinotega', 'type': 'Diocese'},
      {'name': 'Diocese of León', 'type': 'Diocese'},
      {'name': 'Diocese of Matagalpa', 'type': 'Diocese'},
      {'name': 'Diocese of Siuna', 'type': 'Diocese'},
    ],
    'Belgium': [
      {'name': 'Archdiocese of Mechelen-Brussels', 'type': 'Archdiocese'},
      {'name': 'Diocese of Antwerp', 'type': 'Diocese'},
      {'name': 'Diocese of Bruges', 'type': 'Diocese'},
      {'name': 'Diocese of Ghent', 'type': 'Diocese'},
      {'name': 'Diocese of Hasselt', 'type': 'Diocese'},
      {'name': 'Diocese of Liège', 'type': 'Diocese'},
      {'name': 'Diocese of Namur', 'type': 'Diocese'},
      {'name': 'Diocese of Tournai', 'type': 'Diocese'},
    ],
    'Netherlands': [
      {'name': 'Archdiocese of Utrecht', 'type': 'Archdiocese'},
      {'name': 'Diocese of Breda', 'type': 'Diocese'},
      {'name': 'Diocese of Groningen-Leeuwarden', 'type': 'Diocese'},
      {'name': 'Diocese of Haarlem-Amsterdam', 'type': 'Diocese'},
      {'name': 'Diocese of Roermond', 'type': 'Diocese'},
      {'name': 'Diocese of Rotterdam', 'type': 'Diocese'},
      {'name': 'Diocese of \'s-Hertogenbosch', 'type': 'Diocese'},
    ],
    'Austria': [
      {'name': 'Archdiocese of Salzburg', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Vienna', 'type': 'Archdiocese'},
      {'name': 'Diocese of Eisenstadt', 'type': 'Diocese'},
      {'name': 'Diocese of Feldkirch', 'type': 'Diocese'},
      {'name': 'Diocese of Graz-Seckau', 'type': 'Diocese'},
      {'name': 'Diocese of Gurk', 'type': 'Diocese'},
      {'name': 'Diocese of Innsbruck', 'type': 'Diocese'},
      {'name': 'Diocese of Linz', 'type': 'Diocese'},
      {'name': 'Diocese of St. Pölten', 'type': 'Diocese'},
    ],
    'Switzerland': [
      {'name': 'Diocese of Basel', 'type': 'Diocese'},
      {'name': 'Diocese of Chur', 'type': 'Diocese'},
      {'name': 'Diocese of Lausanne, Geneva and Fribourg', 'type': 'Diocese'},
      {'name': 'Diocese of Lugano', 'type': 'Diocese'},
      {'name': 'Diocese of Saint-Maurice', 'type': 'Diocese'},
      {'name': 'Diocese of Sion', 'type': 'Diocese'},
    ],
    'Czech Republic': [
      {'name': 'Archdiocese of Prague', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Olomouc', 'type': 'Archdiocese'},
      {'name': 'Diocese of Brno', 'type': 'Diocese'},
      {'name': 'Diocese of České Budějovice', 'type': 'Diocese'},
      {'name': 'Diocese of Hradec Králové', 'type': 'Diocese'},
      {'name': 'Diocese of Litoměřice', 'type': 'Diocese'},
      {'name': 'Diocese of Ostrava-Opava', 'type': 'Diocese'},
      {'name': 'Diocese of Plzeň', 'type': 'Diocese'},
    ],
    'Slovakia': [
      {'name': 'Archdiocese of Bratislava', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Košice', 'type': 'Archdiocese'},
      {'name': 'Diocese of Banská Bystrica', 'type': 'Diocese'},
      {'name': 'Diocese of Nitra', 'type': 'Diocese'},
      {'name': 'Diocese of Rožňava', 'type': 'Diocese'},
      {'name': 'Diocese of Spiš', 'type': 'Diocese'},
      {'name': 'Diocese of Trnava', 'type': 'Diocese'},
      {'name': 'Diocese of Žilina', 'type': 'Diocese'},
    ],
    'Hungary': [
      {'name': 'Archdiocese of Esztergom-Budapest', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Eger', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Kalocsa-Kecskemét', 'type': 'Archdiocese'},
      {'name': 'Diocese of Debrecen-Nyíregyháza', 'type': 'Diocese'},
      {'name': 'Diocese of Győr', 'type': 'Diocese'},
      {'name': 'Diocese of Pécs', 'type': 'Diocese'},
      {'name': 'Diocese of Szeged-Csanád', 'type': 'Diocese'},
      {'name': 'Diocese of Szombathely', 'type': 'Diocese'},
      {'name': 'Diocese of Vác', 'type': 'Diocese'},
      {'name': 'Diocese of Veszprém', 'type': 'Diocese'},
    ],
    'Romania': [
      {'name': 'Archdiocese of Bucharest', 'type': 'Archdiocese'},
      {'name': 'Diocese of Alba Iulia', 'type': 'Diocese'},
      {'name': 'Diocese of Iași', 'type': 'Diocese'},
      {'name': 'Diocese of Oradea Mare', 'type': 'Diocese'},
      {'name': 'Diocese of Satu Mare', 'type': 'Diocese'},
      {'name': 'Diocese of Timișoara', 'type': 'Diocese'},
    ],
    'Croatia': [
      {'name': 'Archdiocese of Zagreb', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Rijeka', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Split-Makarska', 'type': 'Archdiocese'},
      {'name': 'Diocese of Đakovo-Osijek', 'type': 'Diocese'},
      {'name': 'Diocese of Gospić-Senj', 'type': 'Diocese'},
      {'name': 'Diocese of Hvar-Brač-Vis', 'type': 'Diocese'},
      {'name': 'Diocese of Krk', 'type': 'Diocese'},
      {'name': 'Diocese of Poreč and Pula', 'type': 'Diocese'},
      {'name': 'Diocese of Požega', 'type': 'Diocese'},
      {'name': 'Diocese of Dubrovnik', 'type': 'Diocese'},
      {'name': 'Diocese of Šibenik', 'type': 'Diocese'},
      {'name': 'Diocese of Sisak', 'type': 'Diocese'},
      {'name': 'Diocese of Varaždin', 'type': 'Diocese'},
    ],
    'Slovenia': [
      {'name': 'Archdiocese of Ljubljana', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Maribor', 'type': 'Archdiocese'},
      {'name': 'Diocese of Celje', 'type': 'Diocese'},
      {'name': 'Diocese of Koper', 'type': 'Diocese'},
      {'name': 'Diocese of Murska Sobota', 'type': 'Diocese'},
      {'name': 'Diocese of Novo Mesto', 'type': 'Diocese'},
    ],
    'Ethiopia': [
      {'name': 'Archdiocese of Addis Ababa', 'type': 'Archdiocese'},
      {'name': 'Diocese of Adigrat', 'type': 'Diocese'},
      {'name': 'Diocese of Bahir Dar', 'type': 'Diocese'},
      {'name': 'Diocese of Emdeber', 'type': 'Diocese'},
      {'name': 'Diocese of Harar', 'type': 'Diocese'},
      {'name': 'Diocese of Hosanna', 'type': 'Diocese'},
      {'name': 'Diocese of Jimma-Bonga', 'type': 'Diocese'},
      {'name': 'Diocese of Mekelle', 'type': 'Diocese'},
      {'name': 'Diocese of Nekemte', 'type': 'Diocese'},
      {'name': 'Diocese of Soddo-Hosanna', 'type': 'Diocese'},
    ],
    'Ghana': [
      {'name': 'Archdiocese of Accra', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Cape Coast', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Kumasi', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Tamale', 'type': 'Archdiocese'},
      {'name': 'Diocese of Damongo', 'type': 'Diocese'},
      {'name': 'Diocese of Ho', 'type': 'Diocese'},
      {'name': 'Diocese of Keta-Akatsi', 'type': 'Diocese'},
      {'name': 'Diocese of Koforidua', 'type': 'Diocese'},
      {'name': 'Diocese of Konongo-Mampong', 'type': 'Diocese'},
      {'name': 'Diocese of Navrongo-Bolgatanga', 'type': 'Diocese'},
      {'name': 'Diocese of Obuasi', 'type': 'Diocese'},
      {'name': 'Diocese of Sekondi-Takoradi', 'type': 'Diocese'},
      {'name': 'Diocese of Sunyani', 'type': 'Diocese'},
      {'name': 'Diocese of Wa', 'type': 'Diocese'},
      {'name': 'Diocese of Wiawso', 'type': 'Diocese'},
      {'name': 'Diocese of Yendi', 'type': 'Diocese'},
    ],
    'Senegal': [
      {'name': 'Archdiocese of Dakar', 'type': 'Archdiocese'},
      {'name': 'Diocese of Kaolack', 'type': 'Diocese'},
      {'name': 'Diocese of Kolda', 'type': 'Diocese'},
      {'name': 'Diocese of Saint-Louis du Sénégal', 'type': 'Diocese'},
      {'name': 'Diocese of Tambacounda', 'type': 'Diocese'},
      {'name': 'Diocese of Thiès', 'type': 'Diocese'},
      {'name': 'Diocese of Ziguinchor', 'type': 'Diocese'},
    ],
    'Burkina Faso': [
      {'name': 'Archdiocese of Ouagadougou', 'type': 'Archdiocese'},
      {'name': 'Diocese of Banfora', 'type': 'Diocese'},
      {'name': 'Diocese of Bobo-Dioulasso', 'type': 'Diocese'},
      {'name': 'Diocese of Dédougou', 'type': 'Diocese'},
      {'name': 'Diocese of Diébougou', 'type': 'Diocese'},
      {'name': 'Diocese of Fada N\'Gourma', 'type': 'Diocese'},
      {'name': 'Diocese of Gaoua', 'type': 'Diocese'},
      {'name': 'Diocese of Kaya', 'type': 'Diocese'},
      {'name': 'Diocese of Koupéla', 'type': 'Diocese'},
      {'name': 'Diocese of Manga', 'type': 'Diocese'},
      {'name': 'Diocese of Nouna', 'type': 'Diocese'},
      {'name': 'Diocese of Ouahigouya', 'type': 'Diocese'},
      {'name': 'Diocese of Tenkodogo', 'type': 'Diocese'},
    ],
    'Mali': [
      {'name': 'Archdiocese of Bamako', 'type': 'Archdiocese'},
      {'name': 'Diocese of Kayes', 'type': 'Diocese'},
      {'name': 'Diocese of Mopti', 'type': 'Diocese'},
      {'name': 'Diocese of Ségou', 'type': 'Diocese'},
      {'name': 'Diocese of Sikasso', 'type': 'Diocese'},
    ],
    'Ivory Coast': [
      {'name': 'Archdiocese of Abidjan', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Bouaké', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Gagnoa', 'type': 'Archdiocese'},
      {'name': 'Diocese of Abengourou', 'type': 'Diocese'},
      {'name': 'Diocese of Bondoukou', 'type': 'Diocese'},
      {'name': 'Diocese of Daloa', 'type': 'Diocese'},
      {'name': 'Diocese of Grand-Bassam', 'type': 'Diocese'},
      {'name': 'Diocese of Katiola', 'type': 'Diocese'},
      {'name': 'Diocese of Korhogo', 'type': 'Diocese'},
      {'name': 'Diocese of Man', 'type': 'Diocese'},
      {'name': 'Diocese of Odienné', 'type': 'Diocese'},
      {'name': 'Diocese of San Pedro-en-Côte d\'Ivoire', 'type': 'Diocese'},
      {'name': 'Diocese of Yamoussoukro', 'type': 'Diocese'},
    ],
    'Madagascar': [
      {'name': 'Archdiocese of Antananarivo', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Fianarantsoa', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Toamasina', 'type': 'Archdiocese'},
      {'name': 'Diocese of Ambanja', 'type': 'Diocese'},
      {'name': 'Diocese of Ambatondrazaka', 'type': 'Diocese'},
      {'name': 'Diocese of Ambositra', 'type': 'Diocese'},
      {'name': 'Diocese of Antsirabe', 'type': 'Diocese'},
      {'name': 'Diocese of Farafangana', 'type': 'Diocese'},
      {'name': 'Diocese of Fenoarivo Atsinanana', 'type': 'Diocese'},
      {'name': 'Diocese of Ihosy', 'type': 'Diocese'},
      {'name': 'Diocese of Mahajanga', 'type': 'Diocese'},
      {'name': 'Diocese of Maintirano', 'type': 'Diocese'},
      {'name': 'Diocese of Mananjary', 'type': 'Diocese'},
      {'name': 'Diocese of Miarinarivo', 'type': 'Diocese'},
      {'name': 'Diocese of Morombe', 'type': 'Diocese'},
      {'name': 'Diocese of Morondava', 'type': 'Diocese'},
      {'name': 'Diocese of Nosy Be', 'type': 'Diocese'},
      {'name': 'Diocese of Port-Bergé', 'type': 'Diocese'},
      {'name': 'Diocese of Toliary', 'type': 'Diocese'},
      {'name': 'Diocese of Tsiroanomandidy', 'type': 'Diocese'},
    ],
    'Vietnam': [
      {'name': 'Archdiocese of Hanoi', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Ho Chi Minh City', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Hue', 'type': 'Archdiocese'},
      {'name': 'Diocese of Bac Ninh', 'type': 'Diocese'},
      {'name': 'Diocese of Ban Me Thuot', 'type': 'Diocese'},
      {'name': 'Diocese of Bui Chu', 'type': 'Diocese'},
      {'name': 'Diocese of Can Tho', 'type': 'Diocese'},
      {'name': 'Diocese of Cao Bang', 'type': 'Diocese'},
      {'name': 'Diocese of Da Lat', 'type': 'Diocese'},
      {'name': 'Diocese of Da Nang', 'type': 'Diocese'},
      {'name': 'Diocese of Hai Phong', 'type': 'Diocese'},
      {'name': 'Diocese of Hung Hoa', 'type': 'Diocese'},
      {'name': 'Diocese of Kon Tum', 'type': 'Diocese'},
      {'name': 'Diocese of Lang Son and Cao Bang', 'type': 'Diocese'},
      {'name': 'Diocese of My Tho', 'type': 'Diocese'},
      {'name': 'Diocese of Nha Trang', 'type': 'Diocese'},
      {'name': 'Diocese of Phan Thiet', 'type': 'Diocese'},
      {'name': 'Diocese of Phat Diem', 'type': 'Diocese'},
      {'name': 'Diocese of Quy Nhon', 'type': 'Diocese'},
      {'name': 'Diocese of Rach Gia', 'type': 'Diocese'},
      {'name': 'Diocese of Thai Binh', 'type': 'Diocese'},
      {'name': 'Diocese of Thanh Hoa', 'type': 'Diocese'},
      {'name': 'Diocese of Vinh', 'type': 'Diocese'},
      {'name': 'Diocese of Vinh Long', 'type': 'Diocese'},
      {'name': 'Diocese of Xuan Loc', 'type': 'Diocese'},
    ],
    'Thailand': [
      {'name': 'Archdiocese of Bangkok', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Thare and Nonseng', 'type': 'Archdiocese'},
      {'name': 'Diocese of Chanthaburi', 'type': 'Diocese'},
      {'name': 'Diocese of Chiang Mai', 'type': 'Diocese'},
      {'name': 'Diocese of Chiang Rai', 'type': 'Diocese'},
      {'name': 'Diocese of Nakhon Ratchasima', 'type': 'Diocese'},
      {'name': 'Diocese of Nakhon Sawan', 'type': 'Diocese'},
      {'name': 'Diocese of Ratchaburi', 'type': 'Diocese'},
      {'name': 'Diocese of Surat Thani', 'type': 'Diocese'},
      {'name': 'Diocese of Ubon Ratchathani', 'type': 'Diocese'},
      {'name': 'Diocese of Udon Thani', 'type': 'Diocese'},
    ],
    'South Korea': [
      {'name': 'Archdiocese of Seoul', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Gwangju', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Daegu', 'type': 'Archdiocese'},
      {'name': 'Diocese of Busan', 'type': 'Diocese'},
      {'name': 'Diocese of Cheongju', 'type': 'Diocese'},
      {'name': 'Diocese of Chuncheon', 'type': 'Diocese'},
      {'name': 'Diocese of Daejeon', 'type': 'Diocese'},
      {'name': 'Diocese of Incheon', 'type': 'Diocese'},
      {'name': 'Diocese of Jeju', 'type': 'Diocese'},
      {'name': 'Diocese of Jeonju', 'type': 'Diocese'},
      {'name': 'Diocese of Masan', 'type': 'Diocese'},
      {'name': 'Diocese of Suwon', 'type': 'Diocese'},
      {'name': 'Diocese of Uijeongbu', 'type': 'Diocese'},
      {'name': 'Diocese of Wonju', 'type': 'Diocese'},
      {'name': 'Diocese of Andong', 'type': 'Diocese'},
    ],
    'Japan': [
      {'name': 'Archdiocese of Tokyo', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Nagasaki', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Osaka', 'type': 'Archdiocese'},
      {'name': 'Diocese of Fukuoka', 'type': 'Diocese'},
      {'name': 'Diocese of Hiroshima', 'type': 'Diocese'},
      {'name': 'Diocese of Kagoshima', 'type': 'Diocese'},
      {'name': 'Diocese of Kyoto', 'type': 'Diocese'},
      {'name': 'Diocese of Nagoya', 'type': 'Diocese'},
      {'name': 'Diocese of Niigata', 'type': 'Diocese'},
      {'name': 'Diocese of Oita', 'type': 'Diocese'},
      {'name': 'Diocese of Saitama', 'type': 'Diocese'},
      {'name': 'Diocese of Sapporo', 'type': 'Diocese'},
      {'name': 'Diocese of Sendai', 'type': 'Diocese'},
      {'name': 'Diocese of Takamatsu', 'type': 'Diocese'},
      {'name': 'Diocese of Yokohama', 'type': 'Diocese'},
    ],
    'China': [
      {'name': 'Archdiocese of Beijing', 'type': 'Archdiocese'},
      {'name': 'Diocese of Anyang', 'type': 'Diocese'},
      {'name': 'Diocese of Baoding', 'type': 'Diocese'},
      {'name': 'Diocese of Changzhi', 'type': 'Diocese'},
      {'name': 'Diocese of Chengde', 'type': 'Diocese'},
      {'name': 'Diocese of Chengdu', 'type': 'Diocese'},
      {'name': 'Diocese of Daming', 'type': 'Diocese'},
      {'name': 'Diocese of Fenyang', 'type': 'Diocese'},
      {'name': 'Diocese of Haimen', 'type': 'Diocese'},
      {'name': 'Diocese of Hanzhong', 'type': 'Diocese'},
      {'name': 'Diocese of Hohhot', 'type': 'Diocese'},
      {'name': 'Diocese of Jinan', 'type': 'Diocese'},
      {'name': 'Diocese of Lanzhou', 'type': 'Diocese'},
      {'name': 'Diocese of Linyi', 'type': 'Diocese'},
      {'name': 'Diocese of Nanchang', 'type': 'Diocese'},
      {'name': 'Diocese of Nanjing', 'type': 'Diocese'},
      {'name': 'Diocese of Ningbo', 'type': 'Diocese'},
      {'name': 'Diocese of Qingdao', 'type': 'Diocese'},
      {'name': 'Diocese of Shanghai', 'type': 'Diocese'},
      {'name': 'Diocese of Shantou', 'type': 'Diocese'},
      {'name': 'Diocese of Shijiazhuang', 'type': 'Diocese'},
      {'name': 'Diocese of Taiyuan', 'type': 'Diocese'},
      {'name': 'Diocese of Tianjin', 'type': 'Diocese'},
      {'name': 'Diocese of Wuhan', 'type': 'Diocese'},
      {'name': 'Diocese of Xi\'an', 'type': 'Diocese'},
      {'name': 'Diocese of Xinjiang', 'type': 'Diocese'},
      {'name': 'Diocese of Xuzhou', 'type': 'Diocese'},
      {'name': 'Diocese of Yantai', 'type': 'Diocese'},
      {'name': 'Diocese of Yinchuan', 'type': 'Diocese'},
      {'name': 'Diocese of Yuanping', 'type': 'Diocese'},
      {'name': 'Diocese of Zhengding', 'type': 'Diocese'},
      {'name': 'Diocese of Zhouzhi', 'type': 'Diocese'},
    ],
    'Myanmar': [
      {'name': 'Archdiocese of Yangon', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Mandalay', 'type': 'Archdiocese'},
      {'name': 'Diocese of Hakha', 'type': 'Diocese'},
      {'name': 'Diocese of Kengtung', 'type': 'Diocese'},
      {'name': 'Diocese of Lashio', 'type': 'Diocese'},
      {'name': 'Diocese of Loikaw', 'type': 'Diocese'},
      {'name': 'Diocese of Mawlamyine', 'type': 'Diocese'},
      {'name': 'Diocese of Myitkyina', 'type': 'Diocese'},
      {'name': 'Diocese of Pathein', 'type': 'Diocese'},
      {'name': 'Diocese of Pekhon', 'type': 'Diocese'},
      {'name': 'Diocese of Pyay', 'type': 'Diocese'},
      {'name': 'Diocese of Taungngu', 'type': 'Diocese'},
    ],
    'Bangladesh': [
      {'name': 'Archdiocese of Dhaka', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Chittagong', 'type': 'Archdiocese'},
      {'name': 'Diocese of Barisal', 'type': 'Diocese'},
      {'name': 'Diocese of Dinajpur', 'type': 'Diocese'},
      {'name': 'Diocese of Khulna', 'type': 'Diocese'},
      {'name': 'Diocese of Mymensingh', 'type': 'Diocese'},
      {'name': 'Diocese of Rajshahi', 'type': 'Diocese'},
      {'name': 'Diocese of Sylhet', 'type': 'Diocese'},
    ],
    'Pakistan': [
      {'name': 'Archdiocese of Karachi', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Lahore', 'type': 'Archdiocese'},
      {'name': 'Diocese of Faisalabad', 'type': 'Diocese'},
      {'name': 'Diocese of Hyderabad', 'type': 'Diocese'},
      {'name': 'Diocese of Islamabad-Rawalpindi', 'type': 'Diocese'},
      {'name': 'Diocese of Multan', 'type': 'Diocese'},
      {'name': 'Diocese of Quetta', 'type': 'Diocese'},
    ],
    'Sri Lanka': [
      {'name': 'Archdiocese of Colombo', 'type': 'Archdiocese'},
      {'name': 'Diocese of Anuradhapura', 'type': 'Diocese'},
      {'name': 'Diocese of Badulla', 'type': 'Diocese'},
      {'name': 'Diocese of Chilaw', 'type': 'Diocese'},
      {'name': 'Diocese of Galle', 'type': 'Diocese'},
      {'name': 'Diocese of Jaffna', 'type': 'Diocese'},
      {'name': 'Diocese of Kandy', 'type': 'Diocese'},
      {'name': 'Diocese of Kurunegala', 'type': 'Diocese'},
      {'name': 'Diocese of Mannar', 'type': 'Diocese'},
      {'name': 'Diocese of Ratnapura', 'type': 'Diocese'},
      {'name': 'Diocese of Trincomalee-Batticaloa', 'type': 'Diocese'},
    ],
    'Taiwan': [
      {'name': 'Archdiocese of Taipei', 'type': 'Archdiocese'},
      {'name': 'Diocese of Chiayi', 'type': 'Diocese'},
      {'name': 'Diocese of Hsinchu', 'type': 'Diocese'},
      {'name': 'Diocese of Hualien', 'type': 'Diocese'},
      {'name': 'Diocese of Kaohsiung', 'type': 'Diocese'},
      {'name': 'Diocese of Taichung', 'type': 'Diocese'},
      {'name': 'Diocese of Tainan', 'type': 'Diocese'},
    ],
    'Mongolia': [
      {'name': 'Apostolic Prefecture of Ulaanbaatar', 'type': 'Apostolic Prefecture'},
    ],
    'North Korea': [
      {'name': 'Diocese of Pyongyang', 'type': 'Diocese'},
      {'name': 'Diocese of Hamhung', 'type': 'Diocese'},
    ],
    'Laos': [
      {'name': 'Apostolic Vicariate of Vientiane', 'type': 'Apostolic Vicariate'},
      {'name': 'Apostolic Vicariate of Savannakhet', 'type': 'Apostolic Vicariate'},
      {'name': 'Apostolic Vicariate of Pakse', 'type': 'Apostolic Vicariate'},
      {'name': 'Apostolic Vicariate of Luang Prabang', 'type': 'Apostolic Vicariate'},
    ],
    'Cambodia': [
      {'name': 'Apostolic Vicariate of Phnom Penh', 'type': 'Apostolic Vicariate'},
      {'name': 'Apostolic Prefecture of Battambang', 'type': 'Apostolic Prefecture'},
    ],
    'Singapore': [
      {'name': 'Archdiocese of Singapore', 'type': 'Archdiocese'},
    ],
    'Malaysia': [
      {'name': 'Archdiocese of Kuala Lumpur', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Kota Kinabalu', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Kuching', 'type': 'Archdiocese'},
      {'name': 'Diocese of Malacca-Johor', 'type': 'Diocese'},
      {'name': 'Diocese of Penang', 'type': 'Diocese'},
      {'name': 'Diocese of Keningau', 'type': 'Diocese'},
      {'name': 'Diocese of Sandakan', 'type': 'Diocese'},
      {'name': 'Diocese of Sibu', 'type': 'Diocese'},
      {'name': 'Diocese of Miri', 'type': 'Diocese'},
    ],
    'Brunei': [
      {'name': 'Apostolic Vicariate of Brunei Darussalam', 'type': 'Apostolic Vicariate'},
    ],
    'Jordan': [
      {'name': 'Apostolic Vicariate of Jordan', 'type': 'Apostolic Vicariate'},
    ],
    'Israel': [
      {'name': 'Latin Patriarchate of Jerusalem', 'type': 'Patriarchate'},
      {'name': 'Patriarchal Exarchate for Catholics of Byzantine Rite', 'type': 'Exarchate'},
    ],
    'Palestine': [
      {'name': 'Latin Patriarchate of Jerusalem', 'type': 'Patriarchate'},
    ],
    'Lebanon': [
      {'name': 'Archdiocese of Beirut', 'type': 'Archdiocese'},
      {'name': 'Diocese of Baalbek', 'type': 'Diocese'},
      {'name': 'Diocese of Sidon', 'type': 'Diocese'},
      {'name': 'Eparchy of Baalbek-Deir El Ahmar', 'type': 'Eparchy'},
      {'name': 'Eparchy of Jounieh', 'type': 'Eparchy'},
    ],
    'Syria': [
      {'name': 'Archdiocese of Damascus', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Aleppo', 'type': 'Archdiocese'},
      {'name': 'Diocese of Lattakia', 'type': 'Diocese'},
    ],
    'Iraq': [
      {'name': 'Archdiocese of Baghdad', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Erbil', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Kirkuk', 'type': 'Archdiocese'},
      {'name': 'Diocese of Basra', 'type': 'Diocese'},
    ],
    'Iran': [
      {'name': 'Archdiocese of Isfahan', 'type': 'Archdiocese'},
      {'name': 'Diocese of Ahvaz', 'type': 'Diocese'},
      {'name': 'Diocese of Urmia', 'type': 'Diocese'},
    ],
    'Turkey': [
      {'name': 'Archdiocese of Istanbul', 'type': 'Archdiocese'},
      {'name': 'Apostolic Vicariate of Anatolia', 'type': 'Apostolic Vicariate'},
      {'name': 'Diocese of Iskenderun', 'type': 'Diocese'},
    ],
    'Egypt': [
      {'name': 'Apostolic Vicariate of Alexandria', 'type': 'Apostolic Vicariate'},
      {'name': 'Apostolic Vicariate of Heliopolis', 'type': 'Apostolic Vicariate'},
    ],
    'Libya': [
      {'name': 'Apostolic Vicariate of Tripoli', 'type': 'Apostolic Vicariate'},
      {'name': 'Apostolic Vicariate of Benghazi', 'type': 'Apostolic Vicariate'},
    ],
    'Tunisia': [
      {'name': 'Archdiocese of Tunis', 'type': 'Archdiocese'},
    ],
    'Algeria': [
      {'name': 'Archdiocese of Algiers', 'type': 'Archdiocese'},
      {'name': 'Diocese of Constantine', 'type': 'Diocese'},
      {'name': 'Diocese of Oran', 'type': 'Diocese'},
      {'name': 'Diocese of Laghouat', 'type': 'Diocese'},
    ],
    'Morocco': [
      {'name': 'Archdiocese of Rabat', 'type': 'Archdiocese'},
      {'name': 'Diocese of Tangier', 'type': 'Diocese'},
    ],
    'Sudan': [
      {'name': 'Archdiocese of Khartoum', 'type': 'Archdiocese'},
      {'name': 'Diocese of El Obeid', 'type': 'Diocese'},
    ],
    'Chad': [
      {'name': 'Archdiocese of N\'Djamena', 'type': 'Archdiocese'},
      {'name': 'Diocese of Doba', 'type': 'Diocese'},
      {'name': 'Diocese of Goré', 'type': 'Diocese'},
      {'name': 'Diocese of Laï', 'type': 'Diocese'},
      {'name': 'Diocese of Moundou', 'type': 'Diocese'},
      {'name': 'Diocese of Pala', 'type': 'Diocese'},
      {'name': 'Diocese of Sarh', 'type': 'Diocese'},
    ],
    'Niger': [
      {'name': 'Archdiocese of Niamey', 'type': 'Archdiocese'},
      {'name': 'Diocese of Maradi', 'type': 'Diocese'},
    ],
    'Mauritania': [
      {'name': 'Diocese of Nouakchott', 'type': 'Diocese'},
    ],
    'Gambia': [
      {'name': 'Diocese of Banjul', 'type': 'Diocese'},
    ],
    'Guinea-Bissau': [
      {'name': 'Diocese of Bissau', 'type': 'Diocese'},
    ],
    'Guinea': [
      {'name': 'Archdiocese of Conakry', 'type': 'Archdiocese'},
      {'name': 'Diocese of Kankan', 'type': 'Diocese'},
      {'name': 'Diocese of N\'Zérékoré', 'type': 'Diocese'},
    ],
    'Sierra Leone': [
      {'name': 'Archdiocese of Freetown', 'type': 'Archdiocese'},
      {'name': 'Diocese of Bo', 'type': 'Diocese'},
      {'name': 'Diocese of Kenema', 'type': 'Diocese'},
      {'name': 'Diocese of Makeni', 'type': 'Diocese'},
    ],
    'Liberia': [
      {'name': 'Archdiocese of Monrovia', 'type': 'Archdiocese'},
      {'name': 'Diocese of Cape Palmas', 'type': 'Diocese'},
      {'name': 'Diocese of Gbarnga', 'type': 'Diocese'},
    ],
    'Togo': [
      {'name': 'Archdiocese of Lomé', 'type': 'Archdiocese'},
      {'name': 'Diocese of Aného', 'type': 'Diocese'},
      {'name': 'Diocese of Atakpamé', 'type': 'Diocese'},
      {'name': 'Diocese of Dapaong', 'type': 'Diocese'},
      {'name': 'Diocese of Kara', 'type': 'Diocese'},
      {'name': 'Diocese of Kpalimé', 'type': 'Diocese'},
      {'name': 'Diocese of Sokodé', 'type': 'Diocese'},
    ],
    'Benin': [
      {'name': 'Archdiocese of Cotonou', 'type': 'Archdiocese'},
      {'name': 'Diocese of Abomey', 'type': 'Diocese'},
      {'name': 'Diocese of Dassa-Zoumé', 'type': 'Diocese'},
      {'name': 'Diocese of Djougou', 'type': 'Diocese'},
      {'name': 'Diocese of Kandi', 'type': 'Diocese'},
      {'name': 'Diocese of Lokossa', 'type': 'Diocese'},
      {'name': 'Diocese of Natitingou', 'type': 'Diocese'},
      {'name': 'Diocese of N\'Dali', 'type': 'Diocese'},
      {'name': 'Diocese of Parakou', 'type': 'Diocese'},
      {'name': 'Diocese of Porto-Novo', 'type': 'Diocese'},
      {'name': 'Diocese of Savalou', 'type': 'Diocese'},
    ],
    'Cameroon': [
      {'name': 'Archdiocese of Douala', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Bamenda', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Bertoua', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Garoua', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Yaoundé', 'type': 'Archdiocese'},
      {'name': 'Diocese of Bafia', 'type': 'Diocese'},
      {'name': 'Diocese of Bafoussam', 'type': 'Diocese'},
      {'name': 'Diocese of Bali', 'type': 'Diocese'},
      {'name': 'Diocese of Batouri', 'type': 'Diocese'},
      {'name': 'Diocese of Buea', 'type': 'Diocese'},
      {'name': 'Diocese of Doumé-Abong\'Mbang', 'type': 'Diocese'},
      {'name': 'Diocese of Edéa', 'type': 'Diocese'},
      {'name': 'Diocese of Eséka', 'type': 'Diocese'},
      {'name': 'Diocese of Kumba', 'type': 'Diocese'},
      {'name': 'Diocese of Kumbo', 'type': 'Diocese'},
      {'name': 'Diocese of Maroua-Mokolo', 'type': 'Diocese'},
      {'name': 'Diocese of Mbalmayo', 'type': 'Diocese'},
      {'name': 'Diocese of Meiganga', 'type': 'Diocese'},
      {'name': 'Diocese of Nkongsamba', 'type': 'Diocese'},
      {'name': 'Diocese of Obala', 'type': 'Diocese'},
      {'name': 'Diocese of Sangmélima', 'type': 'Diocese'},
      {'name': 'Diocese of Yokadouma', 'type': 'Diocese'},
    ],
    'Central African Republic': [
      {'name': 'Archdiocese of Bangui', 'type': 'Archdiocese'},
      {'name': 'Diocese of Bambari', 'type': 'Diocese'},
      {'name': 'Diocese of Bangassou', 'type': 'Diocese'},
      {'name': 'Diocese of Berberati', 'type': 'Diocese'},
      {'name': 'Diocese of Bouar', 'type': 'Diocese'},
      {'name': 'Diocese of Bossangoa', 'type': 'Diocese'},
      {'name': 'Diocese of Carnot', 'type': 'Diocese'},
      {'name': 'Diocese of Kaga-Bandoro', 'type': 'Diocese'},
      {'name': 'Diocese of Mbaïki', 'type': 'Diocese'},
    ],
    'Equatorial Guinea': [
      {'name': 'Archdiocese of Malabo', 'type': 'Archdiocese'},
      {'name': 'Diocese of Bata', 'type': 'Diocese'},
      {'name': 'Diocese of Ebebiyín', 'type': 'Diocese'},
      {'name': 'Diocese of Evinayong', 'type': 'Diocese'},
    ],
    'Gabon': [
      {'name': 'Archdiocese of Libreville', 'type': 'Archdiocese'},
      {'name': 'Diocese of Franceville', 'type': 'Diocese'},
      {'name': 'Diocese of Mouila', 'type': 'Diocese'},
      {'name': 'Diocese of Oyem', 'type': 'Diocese'},
      {'name': 'Diocese of Port-Gentil', 'type': 'Diocese'},
    ],
    'Congo': [
      {'name': 'Archdiocese of Brazzaville', 'type': 'Archdiocese'},
      {'name': 'Diocese of Dolisie', 'type': 'Diocese'},
      {'name': 'Diocese of Gamboma', 'type': 'Diocese'},
      {'name': 'Diocese of Impfondo', 'type': 'Diocese'},
      {'name': 'Diocese of Kinkala', 'type': 'Diocese'},
      {'name': 'Diocese of Nkayi', 'type': 'Diocese'},
      {'name': 'Diocese of Ouesso', 'type': 'Diocese'},
      {'name': 'Diocese of Owando', 'type': 'Diocese'},
      {'name': 'Diocese of Pointe-Noire', 'type': 'Diocese'},
    ],
    'Democratic Republic of the Congo': [
      {'name': 'Archdiocese of Kinshasa', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Bukavu', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Kananga', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Kisangani', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Lubumbashi', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Mbandaka-Bikoro', 'type': 'Archdiocese'},
      {'name': 'Diocese of Basankusu', 'type': 'Diocese'},
      {'name': 'Diocese of Boma', 'type': 'Diocese'},
      {'name': 'Diocese of Butembo-Beni', 'type': 'Diocese'},
      {'name': 'Diocese of Doruma-Dungu', 'type': 'Diocese'},
      {'name': 'Diocese of Goma', 'type': 'Diocese'},
      {'name': 'Diocese of Idiofa', 'type': 'Diocese'},
      {'name': 'Diocese of Inongo', 'type': 'Diocese'},
      {'name': 'Diocese of Isangi', 'type': 'Diocese'},
      {'name': 'Diocese of Kabinda', 'type': 'Diocese'},
      {'name': 'Diocese of Kalemie-Kirungu', 'type': 'Diocese'},
      {'name': 'Diocese of Kamina', 'type': 'Diocese'},
      {'name': 'Diocese of Kasongo', 'type': 'Diocese'},
      {'name': 'Diocese of Kikwit', 'type': 'Diocese'},
      {'name': 'Diocese of Kilwa-Kasenga', 'type': 'Diocese'},
      {'name': 'Diocese of Kole', 'type': 'Diocese'},
      {'name': 'Diocese of Kolwezi', 'type': 'Diocese'},
      {'name': 'Diocese of Kongolo', 'type': 'Diocese'},
      {'name': 'Diocese of Lisala', 'type': 'Diocese'},
      {'name': 'Diocese of Lolo', 'type': 'Diocese'},
      {'name': 'Diocese of Luebo', 'type': 'Diocese'},
      {'name': 'Diocese of Luiza', 'type': 'Diocese'},
      {'name': 'Diocese of Mahagi-Nioka', 'type': 'Diocese'},
      {'name': 'Diocese of Matadi', 'type': 'Diocese'},
      {'name': 'Diocese of Mbujimayi', 'type': 'Diocese'},
      {'name': 'Diocese of Mweka', 'type': 'Diocese'},
      {'name': 'Diocese of Popokabaka', 'type': 'Diocese'},
      {'name': 'Diocese of Sakania-Kipushi', 'type': 'Diocese'},
      {'name': 'Diocese of Tshumbe', 'type': 'Diocese'},
      {'name': 'Diocese of Uvira', 'type': 'Diocese'},
      {'name': 'Diocese of Wamba', 'type': 'Diocese'},
    ],
    'Angola': [
      {'name': 'Archdiocese of Luanda', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Huambo', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Lubango', 'type': 'Archdiocese'},
      {'name': 'Diocese of Benguela', 'type': 'Diocese'},
      {'name': 'Diocese of Cabinda', 'type': 'Diocese'},
      {'name': 'Diocese of Caxito', 'type': 'Diocese'},
      {'name': 'Diocese of Dundo', 'type': 'Diocese'},
      {'name': 'Diocese of Kwito-Bié', 'type': 'Diocese'},
      {'name': 'Diocese of Malanje', 'type': 'Diocese'},
      {'name': 'Diocese of Mbanza Congo', 'type': 'Diocese'},
      {'name': 'Diocese of Menongue', 'type': 'Diocese'},
      {'name': 'Diocese of Namibe', 'type': 'Diocese'},
      {'name': 'Diocese of Ndalatando', 'type': 'Diocese'},
      {'name': 'Diocese of Ondjiva', 'type': 'Diocese'},
      {'name': 'Diocese of Sumbe', 'type': 'Diocese'},
      {'name': 'Diocese of Uíge', 'type': 'Diocese'},
      {'name': 'Diocese of Viana', 'type': 'Diocese'},
    ],
    'Mozambique': [
      {'name': 'Archdiocese of Maputo', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Beira', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Nampula', 'type': 'Archdiocese'},
      {'name': 'Diocese of Chimoio', 'type': 'Diocese'},
      {'name': 'Diocese of Gurué', 'type': 'Diocese'},
      {'name': 'Diocese of Inhambane', 'type': 'Diocese'},
      {'name': 'Diocese of Lichinga', 'type': 'Diocese'},
      {'name': 'Diocese of Nacala', 'type': 'Diocese'},
      {'name': 'Diocese of Pemba', 'type': 'Diocese'},
      {'name': 'Diocese of Quelimane', 'type': 'Diocese'},
      {'name': 'Diocese of Tete', 'type': 'Diocese'},
      {'name': 'Diocese of Xai-Xai', 'type': 'Diocese'},
    ],
    'Zambia': [
      {'name': 'Archdiocese of Lusaka', 'type': 'Archdiocese'},
      {'name': 'Diocese of Chipata', 'type': 'Diocese'},
      {'name': 'Diocese of Kabwe', 'type': 'Diocese'},
      {'name': 'Diocese of Kasama', 'type': 'Diocese'},
      {'name': 'Diocese of Livingstone', 'type': 'Diocese'},
      {'name': 'Diocese of Mansa', 'type': 'Diocese'},
      {'name': 'Diocese of Mongu', 'type': 'Diocese'},
      {'name': 'Diocese of Mpika', 'type': 'Diocese'},
      {'name': 'Diocese of Ndola', 'type': 'Diocese'},
      {'name': 'Diocese of Solwezi', 'type': 'Diocese'},
    ],
    'Zimbabwe': [
      {'name': 'Archdiocese of Harare', 'type': 'Archdiocese'},
      {'name': 'Diocese of Bulawayo', 'type': 'Diocese'},
      {'name': 'Diocese of Gweru', 'type': 'Diocese'},
      {'name': 'Diocese of Hwange', 'type': 'Diocese'},
      {'name': 'Diocese of Masvingo', 'type': 'Diocese'},
      {'name': 'Diocese of Mutare', 'type': 'Diocese'},
    ],
    'Botswana': [
      {'name': 'Diocese of Gaborone', 'type': 'Diocese'},
    ],
    'Namibia': [
      {'name': 'Archdiocese of Windhoek', 'type': 'Archdiocese'},
      {'name': 'Diocese of Keetmanshoop', 'type': 'Diocese'},
    ],
    'Lesotho': [
      {'name': 'Archdiocese of Maseru', 'type': 'Archdiocese'},
      {'name': 'Diocese of Leribe', 'type': 'Diocese'},
      {'name': 'Diocese of Mohale\'s Hoek', 'type': 'Diocese'},
      {'name': 'Diocese of Qacha\'s Nek', 'type': 'Diocese'},
    ],
    'Swaziland': [
      {'name': 'Diocese of Manzini', 'type': 'Diocese'},
    ],
    'Malawi': [
      {'name': 'Archdiocese of Lilongwe', 'type': 'Archdiocese'},
      {'name': 'Diocese of Blantyre', 'type': 'Diocese'},
      {'name': 'Diocese of Chikwawa', 'type': 'Diocese'},
      {'name': 'Diocese of Dedza', 'type': 'Diocese'},
      {'name': 'Diocese of Karonga', 'type': 'Diocese'},
      {'name': 'Diocese of Mzuzu', 'type': 'Diocese'},
      {'name': 'Diocese of Zomba', 'type': 'Diocese'},
    ],
    'Rwanda': [
      {'name': 'Archdiocese of Kigali', 'type': 'Archdiocese'},
      {'name': 'Diocese of Butare', 'type': 'Diocese'},
      {'name': 'Diocese of Byumba', 'type': 'Diocese'},
      {'name': 'Diocese of Cyangugu', 'type': 'Diocese'},
      {'name': 'Diocese of Gikongoro', 'type': 'Diocese'},
      {'name': 'Diocese of Kabgayi', 'type': 'Diocese'},
      {'name': 'Diocese of Kibungo', 'type': 'Diocese'},
      {'name': 'Diocese of Nyundo', 'type': 'Diocese'},
      {'name': 'Diocese of Ruhengeri', 'type': 'Diocese'},
    ],
    'Burundi': [
      {'name': 'Archdiocese of Gitega', 'type': 'Archdiocese'},
      {'name': 'Diocese of Bubanza', 'type': 'Diocese'},
      {'name': 'Diocese of Bujumbura', 'type': 'Diocese'},
      {'name': 'Diocese of Bururi', 'type': 'Diocese'},
      {'name': 'Diocese of Muyinga', 'type': 'Diocese'},
      {'name': 'Diocese of Ngozi', 'type': 'Diocese'},
      {'name': 'Diocese of Rutana', 'type': 'Diocese'},
      {'name': 'Diocese of Ruyigi', 'type': 'Diocese'},
    ],
    'New Zealand': [
      {'name': 'Archdiocese of Wellington', 'type': 'Archdiocese'},
      {'name': 'Diocese of Auckland', 'type': 'Diocese'},
      {'name': 'Diocese of Christchurch', 'type': 'Diocese'},
      {'name': 'Diocese of Dunedin', 'type': 'Diocese'},
      {'name': 'Diocese of Hamilton', 'type': 'Diocese'},
      {'name': 'Diocese of Palmerston North', 'type': 'Diocese'},
    ],
    'Papua New Guinea': [
      {'name': 'Archdiocese of Mount Hagen', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Madang', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Port Moresby', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Rabaul', 'type': 'Archdiocese'},
      {'name': 'Diocese of Aitape', 'type': 'Diocese'},
      {'name': 'Diocese of Bereina', 'type': 'Diocese'},
      {'name': 'Diocese of Daru-Kiunga', 'type': 'Diocese'},
      {'name': 'Diocese of Kerema', 'type': 'Diocese'},
      {'name': 'Diocese of Kimbe', 'type': 'Diocese'},
      {'name': 'Diocese of Lae', 'type': 'Diocese'},
      {'name': 'Diocese of Mendi', 'type': 'Diocese'},
      {'name': 'Diocese of Vanimo', 'type': 'Diocese'},
      {'name': 'Diocese of Wabag', 'type': 'Diocese'},
      {'name': 'Diocese of Wewak', 'type': 'Diocese'},
    ],
    'Fiji': [
      {'name': 'Archdiocese of Suva', 'type': 'Archdiocese'},
    ],
    'Solomon Islands': [
      {'name': 'Diocese of Auki', 'type': 'Diocese'},
      {'name': 'Diocese of Gizo', 'type': 'Diocese'},
      {'name': 'Diocese of Honiara', 'type': 'Diocese'},
    ],
    'Vanuatu': [
      {'name': 'Diocese of Port Vila', 'type': 'Diocese'},
    ],
    'Tonga': [
      {'name': 'Diocese of Nuku\'alofa', 'type': 'Diocese'},
    ],
    'Samoa': [
      {'name': 'Archdiocese of Samoa-Apia', 'type': 'Archdiocese'},
    ],
    'Tuvalu': [
      {'name': 'Catholic Mission of Funafuti', 'type': 'Mission'},
    ],
    'Palau': [
      {'name': 'Catholic Mission of Koror', 'type': 'Mission'},
    ],
    'Marshall Islands': [
      {'name': 'Catholic Mission of Majuro', 'type': 'Mission'},
    ],
    'Micronesia': [
      {'name': 'Diocese of Caroline Islands', 'type': 'Diocese'},
    ],
    'Kiribati': [
      {'name': 'Diocese of Tarawa and Nauru', 'type': 'Diocese'},
    ],
    'Nauru': [
      {'name': 'Diocese of Tarawa and Nauru', 'type': 'Diocese'},
    ],
    'Denmark': [
      {'name': 'Diocese of Copenhagen', 'type': 'Diocese'},
    ],
    'Sweden': [
      {'name': 'Diocese of Stockholm', 'type': 'Diocese'},
    ],
    'Norway': [
      {'name': 'Diocese of Oslo', 'type': 'Diocese'},
      {'name': 'Diocese of Trondheim', 'type': 'Diocese'},
    ],
    'Finland': [
      {'name': 'Diocese of Helsinki', 'type': 'Diocese'},
    ],
    'Iceland': [
      {'name': 'Diocese of Reykjavík', 'type': 'Diocese'},
    ],
    'Estonia': [
      {'name': 'Apostolic Administration of Estonia', 'type': 'Apostolic Administration'},
    ],
    'Latvia': [
      {'name': 'Archdiocese of Riga', 'type': 'Archdiocese'},
      {'name': 'Diocese of Jelgava', 'type': 'Diocese'},
      {'name': 'Diocese of Liepāja', 'type': 'Diocese'},
      {'name': 'Diocese of Rēzekne-Aglona', 'type': 'Diocese'},
    ],
    'Lithuania': [
      {'name': 'Archdiocese of Kaunas', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Vilnius', 'type': 'Archdiocese'},
      {'name': 'Diocese of Kaišiadorys', 'type': 'Diocese'},
      {'name': 'Diocese of Panevėžys', 'type': 'Diocese'},
      {'name': 'Diocese of Šiauliai', 'type': 'Diocese'},
      {'name': 'Diocese of Telšiai', 'type': 'Diocese'},
      {'name': 'Diocese of Vilkaviškis', 'type': 'Diocese'},
    ],
    'Russia': [
      {'name': 'Archdiocese of Moscow', 'type': 'Archdiocese'},
      {'name': 'Diocese of Irkutsk', 'type': 'Diocese'},
      {'name': 'Diocese of Kaliningrad', 'type': 'Diocese'},
      {'name': 'Diocese of Krasnodar', 'type': 'Diocese'},
      {'name': 'Diocese of Magadan', 'type': 'Diocese'},
      {'name': 'Diocese of Novosibirsk', 'type': 'Diocese'},
      {'name': 'Diocese of Omsk', 'type': 'Diocese'},
      {'name': 'Diocese of Rostov-on-Don', 'type': 'Diocese'},
      {'name': 'Diocese of Saint Petersburg', 'type': 'Diocese'},
      {'name': 'Diocese of Saratov', 'type': 'Diocese'},
      {'name': 'Diocese of Tomsk', 'type': 'Diocese'},
      {'name': 'Diocese of Vladivostok', 'type': 'Diocese'},
      {'name': 'Diocese of Volgograd', 'type': 'Diocese'},
      {'name': 'Diocese of Voronezh', 'type': 'Diocese'},
      {'name': 'Diocese of Yakutsk', 'type': 'Diocese'},
      {'name': 'Diocese of Yekaterinburg', 'type': 'Diocese'},
    ],
    'Belarus': [
      {'name': 'Archdiocese of Minsk-Mohilev', 'type': 'Archdiocese'},
      {'name': 'Diocese of Grodno', 'type': 'Diocese'},
      {'name': 'Diocese of Pinsk', 'type': 'Diocese'},
      {'name': 'Diocese of Vitebsk', 'type': 'Diocese'},
    ],
    'Ukraine': [
      {'name': 'Archdiocese of Lviv', 'type': 'Archdiocese'},
      {'name': 'Diocese of Kyiv-Zhytomyr', 'type': 'Diocese'},
      {'name': 'Diocese of Kharkiv-Zaporizhzhia', 'type': 'Diocese'},
      {'name': 'Diocese of Lutsk', 'type': 'Diocese'},
      {'name': 'Diocese of Mukachevo', 'type': 'Diocese'},
      {'name': 'Diocese of Odessa-Simferopol', 'type': 'Diocese'},
    ],
    'Moldova': [
      {'name': 'Diocese of Chișinău', 'type': 'Diocese'},
    ]
  };

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );
      
      if (image != null) {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          setState(() {
            _selectedImage = File(image.path);
            _webImageBytes = bytes;
          });
        } else {
          setState(() {
            _selectedImage = File(image.path);
            _webImageBytes = null;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );
      
      if (image != null) {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          setState(() {
            _selectedImage = File(image.path);
            _webImageBytes = bytes;
          });
        } else {
          setState(() {
            _selectedImage = File(image.path);
            _webImageBytes = null;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error taking photo: $e')),
        );
      }
    }
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromCamera();
                },
              ),
              if (_selectedImage != null)
                ListTile(
                  leading: const Icon(Icons.delete),
                  title: const Text('Remove image'),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedImage = null;
                      _webImageBytes = null;
                    });
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _createChoir() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final formData = _formKey.currentState!.value;
      final authController = Provider.of<AuthController>(context, listen: false);
      final choirController = Provider.of<ChoirController>(context, listen: false);
      
      // Upload image if selected
      String? imageUrl;
      if (_selectedImage != null) {
        // For now, we'll use a placeholder URL or implement file upload service
        // In a real app, you'd upload to Firebase Storage or similar
        imageUrl = 'local_file://${_selectedImage!.path}';
      }

      // Get parish name from either form field or custom controller
      String parishName;
      if (_isCustomParish) {
        parishName = _customParishController.text.trim();
      } else {
        parishName = formData['parish'] as String? ?? '';
      }
      
      // Get diocese name from either form field or custom controller
      String dioceseName;
      if (_isCustomDiocese) {
        dioceseName = _customDioceseController.text.trim();
      } else {
        dioceseName = formData['diocese'] ?? '';
      }

      final success = await choirController.createChoir(
        name: formData['name'] ?? '',
        description: formData['description'] ?? '',
        adminId: authController.currentUser!.id,
        leaderId: formData['leaderId'], // Optional: could be same as admin
        imageUrl: imageUrl,
        country: formData['country'] ?? '',
        diocese: dioceseName,
        parish: parishName,
      );

      if (success) {
        Get.back();
        Get.snackbar(
          'Success',
          'Choir created successfully!',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Error',
          choirController.errorMessage ?? 'Failed to create choir',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Choir'),
        iconTheme: const IconThemeData(color: Colors.black),
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: _showImagePicker,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: _selectedImage == null ? Theme.of(context).colorScheme.primary : null,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  child: _selectedImage == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate,
                              size: 40,
                              color: Colors.white,
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Add Photo',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: kIsWeb && _webImageBytes != null
                            ? Image.memory(
                                _webImageBytes!,
                                fit: BoxFit.cover,
                                width: 120,
                                height: 120,
                              )
                            : !kIsWeb && _selectedImage != null
                            ? Image.file(
                                _selectedImage!,
                                fit: BoxFit.cover,
                                width: 120,
                                height: 120,
                              )
                            : Container(
                                width: 120,
                                height: 120,
                                color: Colors.grey[300],
                                child: const Icon(Icons.image, color: Colors.grey),
                              ),
                        ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              Text(
                'Create New Choir',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 8),
              
              Text(
                'Fill in the details below to create a new choir',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
              
              const SizedBox(height: 32),
              
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: FormBuilder(
                    key: _formKey,
                    initialValue: const {
                      'name': '',
                      'description': '',
                      'country': '',
                      'diocese': '',
                      'parish': '',
                    },
                    child: Column(
                      children: [
                        FormBuilderTextField(
                          name: 'name',
                          decoration: const InputDecoration(
                            labelText: 'Choir Name',
                            hintText: 'Enter the choir name',
                            prefixIcon: Icon(Icons.music_note),
                          ),
                          validator: FormBuilderValidators.compose([
                            FormBuilderValidators.required(),
                            FormBuilderValidators.minLength(3),
                            FormBuilderValidators.maxLength(50),
                          ]),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        FormBuilderTextField(
                          name: 'description',
                          decoration: const InputDecoration(
                            labelText: 'Description (Optional)',
                            hintText: 'Describe the choir (optional)',
                            prefixIcon: Icon(Icons.description),
                          ),
                          maxLines: 3,
                          validator: FormBuilderValidators.maxLength(200),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Searchable country dropdown
                        FormBuilderField<String>(
                          name: 'country',
                          validator: FormBuilderValidators.compose([
                            FormBuilderValidators.required(),
                          ]),
                          builder: (field) {
                            return Column(
                              children: [
                                TextField(
                                  controller: _countrySearchController,
                                  readOnly: _selectedCountry != null,
                                  decoration: InputDecoration(
                                    labelText: 'Country *',
                                    hintText: _selectedCountry ?? 'Search or select a country',
                                    prefixIcon: const Icon(Icons.public),
                                    suffixIcon: _selectedCountry != null
                                        ? IconButton(
                                            icon: const Icon(Icons.clear),
                                            onPressed: () {
                                              if (!mounted) return;
                                              setState(() {
                                                _selectedCountry = null;
                                                _countrySearchController.clear();
                                                _isCountryDropdownOpen = false;
                                                _selectedDiocese = null;
                                                _dioceseSearchController.clear();
                                                _isCustomDiocese = false;
                                                try {
                                                  _customDioceseController.clear();
                                                } catch (e) {
                                                  // Ignore clear errors during state changes
                                                }
                                              });
                                              field.didChange('');
                                              _formKey.currentState?.fields['diocese']?.didChange('');
                                              _formKey.currentState?.fields['parish']?.didChange('');
                                            },
                                          )
                                        : IconButton(
                                            icon: Icon(_isCountryDropdownOpen ? Icons.expand_less : Icons.expand_more),
                                            onPressed: () {
                                              if (!mounted) return;
                                              setState(() {
                                                _isCountryDropdownOpen = !_isCountryDropdownOpen;
                                              });
                                            },
                                          ),
                                    border: const OutlineInputBorder(),
                                    errorText: field.errorText,
                                  ),
                                  onTap: () {
                                    if (mounted && _selectedCountry == null) {
                                      setState(() {
                                        _isCountryDropdownOpen = true;
                                      });
                                    }
                                  },
                                  onChanged: (value) {
                                    if (mounted) {
                                      setState(() {
                                        _isCountryDropdownOpen = true;
                                        _selectedCountry = null;
                                      });
                                      field.didChange('');
                                    }
                                  },
                                ),
                                
                                if (_isCountryDropdownOpen) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    height: 200,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: ListView.builder(
                                      itemCount: _filteredCountries.length,
                                      itemBuilder: (context, index) {
                                        final country = _filteredCountries[index];
                                        return ListTile(
                                          dense: true,
                                          leading: Text(
                                            country['flag'] ?? '',
                                            style: const TextStyle(fontSize: 20),
                                          ),
                                          title: Text(country['name'] ?? 'Unknown Country'),
                                          onTap: () {
                                            if (!mounted) return;
                                            setState(() {
                                              _selectedCountry = country['name'];
                                              _countrySearchController.text = country['name'] ?? '';
                                              _isCountryDropdownOpen = false;
                                              _selectedDiocese = null;
                                              _dioceseSearchController.clear();
                                              _isCustomDiocese = false;
                                              _customDioceseController.clear();
                                            });
                                            if (mounted) {
                                              final countryName = country['name'];
                                              if (countryName != null) {
                                                field.didChange(countryName);
                                              }
                                              _formKey.currentState?.fields['diocese']?.didChange('');
                                              _formKey.currentState?.fields['parish']?.didChange('');
                                            }
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                ],
                                
                              ],
                            );
                          },
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Simple diocese dropdown with custom option in list
                        FormBuilderDropdown<String>(
                          name: 'diocese',
                          decoration: InputDecoration(
                            labelText: 'Diocese/Archdiocese',
                            hintText: _selectedCountry == null 
                                ? 'Please select a country first'
                                : 'Select a diocese or enter custom',
                            prefixIcon: const Icon(Icons.account_balance),
                          ),
                          validator: (value) {
                            if (_isCustomDiocese) {
                              return null; // Custom diocese validation handled by TextFormField below
                            }
                            if (value == null || value.isEmpty || value == 'CUSTOM_DIOCESE') {
                              return 'Please select a diocese';
                            }
                            return null;
                          },
                          items: _selectedCountry != null 
                              ? [
                                  // Add custom diocese option at the top
                                  DropdownMenuItem<String>(
                                    value: 'CUSTOM_DIOCESE',
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.edit,
                                          size: 16,
                                          color: Colors.orange,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Enter a custom Diocese',
                                            style: TextStyle(
                                              color: Colors.orange[700],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Add separator
                                  const DropdownMenuItem<String>(
                                    value: null,
                                    enabled: false,
                                    child: Divider(height: 1),
                                  ),
                                  // Add all predefined dioceses
                                  ..._availableDioceses.map((diocese) {
                                    final isArchdiocese = diocese['type'] == 'Archdiocese';
                                    return DropdownMenuItem<String>(
                                      value: diocese['name'],
                                      child: Row(
                                        children: [
                                          Icon(
                                            isArchdiocese ? Icons.account_balance : Icons.location_city,
                                            size: 16,
                                            color: isArchdiocese ? Colors.purple : Colors.blue,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text.rich(
                                              TextSpan(
                                                children: [
                                                  TextSpan(text: diocese['name'] ?? 'Unknown Diocese'),
                                                  TextSpan(
                                                    text: ' (${diocese['type'] ?? 'Diocese'})',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: isArchdiocese ? Colors.purple : Colors.blue,
                                                      fontWeight: FontWeight.w400,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ]
                              : [],
                          onChanged: (value) {
                            if (value == 'CUSTOM_DIOCESE') {
                              setState(() {
                                _isCustomDiocese = true;
                                _selectedDiocese = null;
                                _customDioceseController.clear();
                              });
                              _formKey.currentState?.fields['parish']?.didChange('');
                            } else if (value != null && mounted) {
                              setState(() {
                                _selectedDiocese = value;
                                _isCustomDiocese = false;
                                _customDioceseController.clear();
                              });
                              _formKey.currentState?.fields['parish']?.didChange('');
                            }
                          },
                        ),
                        
                        // Show custom diocese input if custom was selected
                        if (_isCustomDiocese) ...[
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _customDioceseController,
                            decoration: const InputDecoration(
                              labelText: 'Custom Diocese Name *',
                              hintText: 'Enter your diocese/archdiocese name',
                              prefixIcon: Icon(Icons.edit),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (_isCustomDiocese && (value == null || value.trim().isEmpty)) {
                                return 'Please enter a diocese name';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              if (mounted) {
                                _formKey.currentState?.fields['parish']?.didChange('');
                              }
                            },
                          ),
                        ],
                        
                        const SizedBox(height: 20),
                        
                        // Searchable parish dropdown with custom option
                        FormBuilderField<String>(
                          name: 'parish',
                          validator: (value) {
                            if (_isCustomParish) {
                              return null; // Custom parish validation handled by TextFormField below
                            }
                            if (value == null || value.isEmpty || value == 'CUSTOM_PARISH') {
                              return 'Please select a parish';
                            }
                            return null;
                          },
                          builder: (field) {
                            final hasSelection = _selectedCountry != null && 
                                (_selectedDiocese != null || (_isCustomDiocese && _customDioceseController.text.isNotEmpty));
                            
                            if (!hasSelection) {
                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.info, color: Colors.grey),
                                    SizedBox(width: 8),
                                    Text(
                                      'Please select country and diocese first',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              );
                            }
                            
                            return Column(
                              children: [
                                TextField(
                                  controller: _parishSearchController,
                                  readOnly: _selectedParish != null,
                                  decoration: InputDecoration(
                                    labelText: 'Parish *',
                                    hintText: _selectedParish?.isNotEmpty == true ? _selectedParish : 'Search or select a parish',
                                    prefixIcon: const Icon(Icons.church),
                                    suffixIcon: _selectedParish != null
                                        ? IconButton(
                                            icon: const Icon(Icons.clear),
                                            onPressed: () {
                                              if (!mounted) return;
                                              setState(() {
                                                _selectedParish = null;
                                                _parishSearchController.clear();
                                                _isParishDropdownOpen = false;
                                              });
                                              field.didChange('');
                                            },
                                          )
                                        : IconButton(
                                            icon: Icon(_isParishDropdownOpen ? Icons.expand_less : Icons.expand_more),
                                            onPressed: () {
                                              if (!mounted) return;
                                              setState(() {
                                                _isParishDropdownOpen = !_isParishDropdownOpen;
                                              });
                                            },
                                          ),
                                    border: const OutlineInputBorder(),
                                    errorText: field.errorText,
                                  ),
                                  onTap: () {
                                    if (mounted && _selectedParish == null) {
                                      setState(() {
                                        _isParishDropdownOpen = true;
                                      });
                                    }
                                  },
                                  onChanged: (value) {
                                    if (mounted && !_isParishDropdownOpen) {
                                      setState(() {
                                        _isParishDropdownOpen = true;
                                      });
                                    }
                                  },
                                ),
                                
                                if (_isParishDropdownOpen) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    constraints: const BoxConstraints(maxHeight: 200),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: ListView(
                                      shrinkWrap: true,
                                      children: [
                                        // Add custom parish option at the top
                                        ListTile(
                                          dense: true,
                                          leading: const Icon(
                                            Icons.edit,
                                            size: 16,
                                            color: Colors.orange,
                                          ),
                                          title: Text(
                                            'Enter a custom Parish',
                                            style: TextStyle(
                                              color: Colors.orange[700],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          onTap: () {
                                            setState(() {
                                              _isCustomParish = true;
                                              _selectedParish = null;
                                              _customParishController.clear();
                                              _isParishDropdownOpen = false;
                                            });
                                            field.didChange('');
                                          },
                                        ),
                                        const Divider(height: 1),
                                        // Add all available parishes
                                        ..._filteredParishes.map((parish) {
                                          return ListTile(
                                            dense: true,
                                            leading: const Icon(
                                              Icons.church,
                                              size: 16,
                                              color: Colors.blue,
                                            ),
                                            title: Text(
                                              parish,
                                              style: const TextStyle(fontSize: 14),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                            onTap: () {
                                              if (!mounted || parish.isEmpty) return;
                                              setState(() {
                                                _selectedParish = parish;
                                                _parishSearchController.text = parish;
                                                _isParishDropdownOpen = false;
                                                _isCustomParish = false;
                                              });
                                              if (mounted) {
                                                field.didChange(parish);
                                              }
                                            },
                                          );
                                        }),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            );
                          },
                        ),
                        
                        // Show custom parish input if custom was selected
                        if (_isCustomParish) ...[
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _customParishController,
                            decoration: const InputDecoration(
                              labelText: 'Custom Parish Name *',
                              hintText: 'Enter your parish name',
                              prefixIcon: Icon(Icons.edit),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (_isCustomParish && (value == null || value.trim().isEmpty)) {
                                return 'Please enter a parish name';
                              }
                              return null;
                            },
                          ),
                        ],
                        
                        const SizedBox(height: 32),
                        
                        Consumer<ChoirController>(
                          builder: (context, choirController, child) {
                            return SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: choirController.isLoading ? null : _createChoir,
                                child: choirController.isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('Create Choir'),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Note',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'You will be set as the choir administrator. You can add members and assign leaders after creating the choir.',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Get filtered countries based on search text
  List<Map<String, String>> get _filteredCountries {
    if (_countrySearchController.text.isEmpty) {
      return _countries;
    }
    return _countries.where((country) {
      final name = country['name'];
      return name != null && name
          .toLowerCase()
          .contains(_countrySearchController.text.toLowerCase());
    }).toList();
  }

  // Get dioceses for selected country
  List<Map<String, String>> get _availableDioceses {
    if (_selectedCountry == null || _selectedCountry!.isEmpty) {
      return [];
    }
    return _diocesesByCountry[_selectedCountry!] ?? [];
  }

  // Get available parishes for selected country and diocese
  List<String> _getAvailableParishes() {
    final selectedCountry = _selectedCountry;
    String? selectedDiocese;
    
    // Handle both predefined and custom diocese
    if (_isCustomDiocese) {
      selectedDiocese = _customDioceseController.text.trim();
    } else {
      selectedDiocese = _selectedDiocese;
    }
    
    if (selectedCountry == null || selectedDiocese == null || selectedDiocese.isEmpty) {
      return [];
    }
    
    // Static list of parishes based on known archdioceses
    List<String> availableParishes = [];
    
    if (selectedCountry == 'United States') {
      if (selectedDiocese == 'Archdiocese of New York') {
        availableParishes = ['St. Patrick\'s Cathedral', 'St. John the Baptist', 'Our Lady of Guadalupe', 'St. Vincent Ferrer'];
      } else if (selectedDiocese == 'Archdiocese of Los Angeles') {
        availableParishes = ['Our Lady of the Angels', 'St. Vibiana', 'Holy Family', 'St. Monica'];
      } else if (selectedDiocese == 'Archdiocese of Chicago') {
        availableParishes = ['Holy Name Cathedral', 'St. Mary of the Angels', 'St. Alphonsus Liguori', 'St. Clement', 'St. Vincent de Paul'];
      } else if (selectedDiocese == 'Archdiocese of Atlanta') {
        availableParishes = ['Cathedral of Christ the King', 'Shrine of the Immaculate Conception', 'St. Thomas More'];
      } else if (selectedDiocese == 'Archdiocese of Baltimore') {
        availableParishes = ['Basilica of the National Shrine', 'St. Alphonsus', 'Cathedral of Mary Our Queen'];
      } else if (selectedDiocese == 'Archdiocese of Boston') {
        availableParishes = ['Cathedral of the Holy Cross', 'St. Leonard', 'Sacred Heart', 'St. Mary'];
      } else if (selectedDiocese == 'Archdiocese of Cincinnati') {
        availableParishes = ['Cathedral Basilica of Saint Peter in Chains', 'St. Francis Xavier', 'Holy Trinity'];
      } else if (selectedDiocese == 'Archdiocese of Denver') {
        availableParishes = ['Cathedral Basilica of the Immaculate Conception', 'St. Joseph', 'Holy Family'];
      } else if (selectedDiocese == 'Archdiocese of Detroit') {
        availableParishes = ['Cathedral of the Most Blessed Sacrament', 'St. Aloysius', 'Sacred Heart Major Seminary'];
      } else if (selectedDiocese == 'Archdiocese of Miami') {
        availableParishes = ['St. Mary Cathedral', 'Gesu Catholic Church', 'St. Augustine'];
      } else if (selectedDiocese == 'Archdiocese of Philadelphia') {
        availableParishes = ['Cathedral Basilica of Saints Peter and Paul', 'Old St. Joseph', 'St. Patrick'];
      } else if (selectedDiocese == 'Archdiocese of San Francisco') {
        availableParishes = ['Cathedral of Saint Mary of the Assumption', 'Old St. Mary', 'St. Ignatius'];
      } else if (selectedDiocese == 'Archdiocese of Seattle') {
        availableParishes = ['St. James Cathedral', 'Sacred Heart', 'St. Joseph'];
      } else if (selectedDiocese == 'Archdiocese of Washington') {
        availableParishes = ['Cathedral of St. Matthew the Apostle', 'St. Patrick', 'Holy Trinity'];
      } else if (selectedDiocese == 'Archdiocese of Hartford') {
        availableParishes = ['Cathedral of St. Joseph', 'St. Mary', 'Sacred Heart', 'St. Augustine'];
      } else if (selectedDiocese == 'Archdiocese of Indianapolis') {
        availableParishes = ['Saints Peter and Paul Cathedral', 'St. Mary', 'Holy Cross', 'St. Joan of Arc'];
      } else if (selectedDiocese == 'Archdiocese of Kansas City in Kansas') {
        availableParishes = ['Cathedral of St. Peter', 'St. Joseph', 'Sacred Heart', 'Holy Family'];
      } else if (selectedDiocese == 'Archdiocese of Louisville') {
        availableParishes = ['Cathedral of the Assumption', 'St. Agnes', 'Sacred Heart', 'St. Bartholomew'];
      } else if (selectedDiocese == 'Archdiocese of Milwaukee') {
        availableParishes = ['Cathedral of St. John the Evangelist', 'St. Josaphat Basilica', 'Gesu Parish'];
      } else if (selectedDiocese == 'Archdiocese of Newark') {
        availableParishes = ['Cathedral Basilica of the Sacred Heart', 'St. Patrick Pro-Cathedral', 'St. Mary'];
      } else if (selectedDiocese == 'Archdiocese of New Orleans') {
        availableParishes = ['St. Louis Cathedral', 'St. Alphonsus', 'Holy Name of Jesus', 'Mater Dolorosa'];
      } else if (selectedDiocese == 'Archdiocese of Oklahoma City') {
        availableParishes = ['Cathedral of Our Lady of Perpetual Help', 'St. Joseph', 'Sacred Heart'];
      } else if (selectedDiocese == 'Archdiocese of Omaha') {
        availableParishes = ['St. Cecilia Cathedral', 'St. Margaret Mary', 'Sacred Heart', 'St. Robert Bellarmine'];
      } else if (selectedDiocese == 'Archdiocese of Portland in Oregon') {
        availableParishes = ['Cathedral of the Immaculate Conception', 'St. Mary Cathedral', 'Holy Redeemer'];
      } else if (selectedDiocese == 'Archdiocese of Saint Louis') {
        availableParishes = ['Cathedral Basilica of St. Louis', 'Old Cathedral', 'St. Francis Xavier'];
      } else if (selectedDiocese == 'Archdiocese of Saint Paul and Minneapolis') {
        availableParishes = ['Cathedral of St. Paul', 'Basilica of St. Mary', 'St. Olaf', 'Holy Trinity'];
      } else if (selectedDiocese == 'Archdiocese of San Antonio') {
        availableParishes = ['San Fernando Cathedral', 'St. Mary', 'Sacred Heart', 'St. Anthony de Padua'];
      } else if (selectedDiocese == 'Archdiocese of Santa Fe') {
        availableParishes = ['Cathedral Basilica of St. Francis of Assisi', 'Loretto Chapel', 'Holy Faith'];
      } else if (selectedDiocese == 'Diocese of Albany') {
        availableParishes = ['Cathedral of the Immaculate Conception', 'St. Mary', 'St. Joseph', 'Sacred Heart'];
      } else if (selectedDiocese == 'Diocese of Alexandria') {
        availableParishes = ['St. Francis Xavier Cathedral', 'St. Mary', 'Sacred Heart', 'St. Anthony'];
      } else if (selectedDiocese == 'Diocese of Allentown') {
        availableParishes = ['Cathedral of St. Catharine of Siena', 'St. Thomas More', 'Sacred Heart'];
      } else if (selectedDiocese == 'Diocese of Arlington') {
        availableParishes = ['Cathedral of St. Thomas More', 'St. Mary', 'Sacred Heart', 'St. John the Apostle'];
      } else if (selectedDiocese == 'Diocese of Austin') {
        availableParishes = ['Cathedral of St. Mary', 'St. Austin', 'Sacred Heart', 'St. Ignatius Martyr'];
      } else if (selectedDiocese == 'Diocese of Baker') {
        availableParishes = ['St. Francis de Sales Cathedral', 'Sacred Heart', 'St. Thomas', 'St. Mary'];
      } else if (selectedDiocese == 'Diocese of Baton Rouge') {
        availableParishes = ['St. Joseph Cathedral', 'St. Agnes', 'Sacred Heart of Jesus', 'Our Lady of Mercy'];
      } else if (selectedDiocese == 'Diocese of Birmingham') {
        availableParishes = ['Cathedral of St. Paul', 'St. Elias Maronite', 'Prince of Peace', 'St. Mark'];
      } else if (selectedDiocese == 'Diocese of Bridgeport') {
        availableParishes = ['St. Augustine Cathedral', 'St. Mary', 'Sacred Heart', 'St. Joseph'];
      } else if (selectedDiocese == 'Diocese of Brooklyn') {
        availableParishes = ['Cathedral Basilica of St. James', 'St. Patrick', 'Our Lady of Lebanon'];
      } else if (selectedDiocese == 'Diocese of Buffalo') {
        availableParishes = ['Cathedral of St. Joseph', 'St. Louis', 'St. Stanislaus', 'Sacred Heart'];
      } else if (selectedDiocese == 'Diocese of Charleston') {
        availableParishes = ['Cathedral of St. John the Baptist', 'St. Mary', 'Sacred Heart', 'St. Anthony'];
      } else if (selectedDiocese == 'Diocese of Cleveland') {
        availableParishes = ['Cathedral of St. John the Evangelist', 'St. Ignatius of Antioch', 'St. Malachi', 'Sacred Heart'];
      }
    } else if (selectedCountry == 'Ghana') {
      if (selectedDiocese == 'Roman Catholic Archdiocese of Accra') {
        availableParishes = [
          'Holy Spirit Cathedral – Accra',
          'Christ the King Parish – Accra',
          'St. Theresa Parish – Osu',
          'Our Lady of Lourdes Parish – Dansoman',
          'St. Francis Xavier Parish',
          'St. Anthony of Padua Parish – Madina',
          'St. Peter Claver Parish – Teshie',
          'St. Paul Parish',
          'University of Ghana Parish – Legon',
          'St. Joseph Worker Parish – Kaneshie',
          'St. Thomas Aquinas Parish – Spintex',
          'Sacred Heart Parish',
          'St. Vincent de Paul Parish – Weija',
          'St. Cyprian Parish – Labone',
          'Christ the Redeemer Parish – East Legon',
          'St. John the Evangelist Parish – Haatso',
          'St. Francis of Assisi Parish – Airport',
          'St. Michael and All Angels Parish – Nungua',
          'St. Margaret Mary Parish',
          'St. Augustine Parish – Cantonments'
        ];
      } else if (selectedDiocese == 'Roman Catholic Archdiocese of Kumasi') {
        availableParishes = [
          'St. Peter Cathedral – Kumasi',
          'St. Cyprian Parish – Kumasi',
          'Christ the King Parish – Kumasi',
          'Sacred Heart Parish – Kumasi',
          'St. Hubert Parish – Kumasi',
          'Our Lady of Lourdes Parish – Kumasi',
          'St. Monica Parish – Kumasi',
          'Holy Family Parish – Kumasi',
          'St. Louis Parish – Kumasi',
          'St. Anne Parish – Kumasi'
        ];
      } else if (selectedDiocese == 'Roman Catholic Archdiocese of Cape Coast') {
        availableParishes = [
          'Christ the King Cathedral – Cape Coast',
          'Holy Cross Parish – Cape Coast',
          'St. Francis Parish – Cape Coast',
          'Sacred Heart Parish – Cape Coast',
          'Our Lady Star of the Sea Parish',
          'St. Monica Parish – Cape Coast',
          'Holy Spirit Parish – Cape Coast',
          'St. Augustine Parish – Cape Coast'
        ];
      } else if (selectedDiocese == 'Roman Catholic Diocese of Ho') {
        availableParishes = [
          'Holy Spirit Cathedral – Ho',
          'St. Paul Parish – Ho',
          'Sacred Heart Parish – Ho',
          'St. Francis Xavier Parish – Ho',
          'Christ the King Parish – Ho'
        ];
      } else if (selectedDiocese == 'Roman Catholic Diocese of Keta-Akatsi') {
        availableParishes = [
          'St. Anthony Parish – Keta',
          'Sacred Heart Parish – Akatsi',
          'St. Francis Parish – Dzodze',
          'Christ the King Parish – Anloga'
        ];
      } else if (selectedDiocese == 'Roman Catholic Diocese of Kpando') {
        availableParishes = [
          'Christ the King Parish – Kpando',
          'St. Paul Parish – Kpando',
          'Sacred Heart Parish – Kpando'
        ];
      } else if (selectedDiocese == 'Roman Catholic Diocese of Jasikan') {
        availableParishes = [
          'St. Augustine Parish – Jasikan',
          'Sacred Heart Parish – Jasikan',
          'Holy Cross Parish – Jasikan'
        ];
      } else if (selectedDiocese == 'Roman Catholic Diocese of Wa') {
        availableParishes = [
          'Our Lady of Lourdes Cathedral – Wa',
          'St. Francis Xavier Parish – Wa',
          'Sacred Heart Parish – Wa'
        ];
      } else if (selectedDiocese == 'Roman Catholic Diocese of Tamale') {
        availableParishes = [
          'Our Lady of Annunciation Cathedral – Tamale',
          'St. Francis Parish – Tamale',
          'Sacred Heart Parish – Tamale',
          'Christ the King Parish – Tamale'
        ];
      } else if (selectedDiocese == 'Roman Catholic Diocese of Navrongo-Bolgatanga') {
        availableParishes = [
          'Our Lady of Seven Sorrows Cathedral – Navrongo',
          'Sacred Heart Parish – Bolgatanga',
          'St. Francis Parish – Navrongo'
        ];
      } else if (selectedDiocese == 'Roman Catholic Diocese of Yendi') {
        availableParishes = [
          'Christ the King Parish – Yendi',
          'Sacred Heart Parish – Yendi'
        ];
      } else if (selectedDiocese == 'Roman Catholic Diocese of Damongo') {
        availableParishes = [
          'St. Paul Parish – Damongo',
          'Sacred Heart Parish – Damongo'
        ];
      } else if (selectedDiocese == 'Roman Catholic Diocese of Sunyani') {
        availableParishes = [
          'Christ the King Cathedral – Sunyani',
          'Sacred Heart Parish – Sunyani',
          'St. James Parish – Sunyani',
          'Our Lady of Lourdes Parish – Sunyani'
        ];
      } else if (selectedDiocese == 'Roman Catholic Diocese of Techiman') {
        availableParishes = [
          'Our Lady of Lourdes Cathedral – Techiman',
          'Sacred Heart Parish – Techiman',
          'St. Anthony Parish – Techiman'
        ];
      } else if (selectedDiocese == 'Roman Catholic Diocese of Goaso') {
        availableParishes = [
          'St. Monica Cathedral – Goaso',
          'Sacred Heart Parish – Goaso'
        ];
      } else if (selectedDiocese == 'Roman Catholic Diocese of Wiawso') {
        availableParishes = [
          'Sacred Heart Cathedral – Wiawso',
          'Christ the King Parish – Wiawso'
        ];
      } else if (selectedDiocese == 'Roman Catholic Diocese of Sekondi-Takoradi') {
        availableParishes = [
          'St. Anthony Cathedral – Takoradi',
          'Sacred Heart Parish – Sekondi',
          'Our Lady Star of the Sea Parish',
          'Christ the King Parish – Takoradi',
          'St. Francis Parish – Sekondi'
        ];
      } else if (selectedDiocese == 'Roman Catholic Diocese of Obuasi') {
        availableParishes = [
          'St. Joseph Cathedral – Obuasi',
          'Sacred Heart Parish – Obuasi',
          'Our Lady of Perpetual Help Parish'
        ];
      } else if (selectedDiocese == 'Roman Catholic Diocese of Konongo-Mampong') {
        availableParishes = [
          'Christ the King Parish – Konongo',
          'Sacred Heart Parish – Mampong'
        ];
      } else if (selectedDiocese == 'Roman Catholic Diocese of Koforidua') {
        availableParishes = [
          'Sacred Heart Cathedral – Koforidua',
          'Christ the King Parish – Koforidua',
          'St. Joseph Parish – Koforidua',
          'Our Lady of Lourdes Parish – Koforidua'
        ];
      } else if (selectedDiocese == 'Roman Catholic Diocese of Donkorkrom') {
        availableParishes = [
          'St. Francis Xavier Parish – Donkorkrom',
          'Sacred Heart Parish – Donkorkrom'
        ];
      } else if (selectedDiocese == 'Roman Catholic Diocese of Asamankese') {
        availableParishes = [
          'St. Francis de Sales Parish – Asamankese',
          'Sacred Heart Parish – Asamankese'
        ];
      }
    } else if (selectedCountry == 'Kenya') {
      if (selectedDiocese == 'Archdiocese of Nairobi') {
        availableParishes = [
          'Holy Family Cathedral – Nairobi',
          'St. Peter Claver Parish',
          'Sacred Heart Parish – Nairobi',
          'Christ the King Parish – Nairobi',
          'Our Lady of Victories Parish'
        ];
      } else if (selectedDiocese == 'Archdiocese of Kisumu') {
        availableParishes = [
          'Our Lady of Victories Cathedral – Kisumu',
          'Sacred Heart Parish – Kisumu',
          'St. Theresa Parish – Kisumu'
        ];
      } else if (selectedDiocese == 'Archdiocese of Mombasa') {
        availableParishes = [
          'Holy Ghost Cathedral – Mombasa',
          'Sacred Heart Parish – Mombasa',
          'St. Teresa Parish – Mombasa'
        ];
      } else if (selectedDiocese == 'Archdiocese of Nyeri') {
        availableParishes = [
          'Sacred Heart Cathedral – Nyeri',
          'St. Peter Claver Parish – Nyeri',
          'Christ the King Parish – Nyeri'
        ];
      }
    } else if (selectedCountry == 'Nigeria') {
      if (selectedDiocese == 'Archdiocese of Lagos') {
        availableParishes = [
          'Holy Cross Cathedral – Lagos',
          'St. Dominic Parish – Yaba',
          'Sacred Heart Parish – Lagos',
          'Christ the King Parish – Lagos'
        ];
      } else if (selectedDiocese == 'Archdiocese of Abuja') {
        availableParishes = [
          'Our Lady Queen of Nigeria Pro-Cathedral',
          'Sacred Heart Parish – Abuja',
          'St. Murumba Parish – Abuja'
        ];
      }
      
      // Continue with existing US dioceses
    } else if (selectedCountry == 'United States') {
      if (selectedDiocese == 'Diocese of Cleveland') {
        availableParishes = ['Cathedral of St. John the Evangelist', 'St. Malachi', 'St. Ignatius of Antioch'];
      } else if (selectedDiocese == 'Diocese of Columbus') {
        availableParishes = ['St. Joseph Cathedral', 'St. Patrick', 'Sacred Heart', 'Holy Family'];
      } else if (selectedDiocese == 'Diocese of Dallas') {
        availableParishes = ['Cathedral Santuario de Guadalupe', 'St. Patrick', 'Holy Trinity', 'St. Monica'];
      } else if (selectedDiocese == 'Diocese of Des Moines') {
        availableParishes = ['Cathedral of St. Ambrose', 'St. Theresa', 'Sacred Heart', 'Holy Trinity'];
      } else if (selectedDiocese == 'Diocese of El Paso') {
        availableParishes = ['Cathedral of St. Patrick', 'St. Joseph', 'Sacred Heart', 'Our Lady of Guadalupe'];
      } else if (selectedDiocese == 'Diocese of Fort Worth') {
        availableParishes = ['Cathedral of St. Patrick', 'St. Andrew', 'Sacred Heart', 'Holy Family'];
      } else if (selectedDiocese == 'Diocese of Fresno') {
        availableParishes = ['St. John\'s Cathedral', 'St. Anthony of Padua', 'Sacred Heart', 'Holy Spirit'];
      } else if (selectedDiocese == 'Diocese of Green Bay') {
        availableParishes = ['Cathedral of St. Francis Xavier', 'St. Willebrord', 'Sacred Heart', 'St. Mary'];
      } else if (selectedDiocese == 'Diocese of Honolulu') {
        availableParishes = ['Cathedral Basilica of Our Lady of Peace', 'St. Augustine', 'Sacred Heart'];
      } else if (selectedDiocese == 'Diocese of Houston') {
        availableParishes = ['Co-Cathedral of the Sacred Heart', 'St. Anne', 'Holy Rosary', 'St. Cyril of Alexandria'];
      } else if (selectedDiocese == 'Diocese of Kansas City') {
        availableParishes = ['Cathedral of the Immaculate Conception', 'St. Peter', 'Sacred Heart', 'Holy Cross'];
      }
    } else if (selectedCountry == 'Kenya') {
      if (selectedDiocese == 'Archdiocese of Kisumu') {
        availableParishes = [
          'St. Teresa Kibuye Cathedral', 'St. Joseph Milimani', 'Holy Cross', 'St. Monica',
          'St. Maria Goretti Nyalenda', 'St. John XXIII Rabuor', 'St. Pantaleon', 'St. Augustine Nyahera',
          'St. Dominic Kianja', 'St. Joseph Nyabondo', 'St. Aloysius Ojolla', 'St. Peter Nyakach',
          'St. Anne Nyamonye', 'St. Mary Yala', 'St. Joseph Ahero', 'Our Lady Queen of Peace Muhoroni',
          'St. John Paul II Obambo', 'Awasi Parish', 'Katito Parish', 'Pap Onditi Parish',
          'Nyando Parish', 'Nyabondo Parish', 'Kombewa Parish', 'Ramba (St. Antony Abbot)',
          'Bondo Parish', 'Usenge Parish', 'Rangala Parish', 'Kirembe Parish'
        ];
      } else if (selectedDiocese == 'Archdiocese of Nairobi') {
        availableParishes = ['Holy Family Cathedral', 'St. Peter\'s Parish', 'St. Austin', 'Holy Trinity', 'Sacred Heart'];
      } else if (selectedDiocese == 'Archdiocese of Mombasa') {
        availableParishes = ['Holy Spirit Parish', 'Sacred Heart Cathedral', 'St. Teresa', 'Holy Ghost'];
      } else if (selectedDiocese == 'Diocese of Eldoret') {
        availableParishes = [
          'Sacred Heart Cathedral Parish – Eldoret',
          'St. Patrick Parish – Kapsabet',
          'Christ the King Parish – Turbo',
          'St. John Parish – Burnt Forest',
          'Holy Family Parish – Iten',
          'St. Joseph Parish – Moiben',
          'Our Lady of Fatima Parish – Ziwa',
          'St. Mary Parish – Kaplamai',
          'Sacred Heart Parish – Uasin Gishu'
        ];
      } else if (selectedDiocese == 'Diocese of Kakamega') {
        availableParishes = [
          'St. Peter and Paul Cathedral Parish – Kakamega',
          'Sacred Heart Parish – Mumias',
          'St. Joseph Parish – Butere',
          'Christ the King Parish – Malava',
          'Holy Family Parish – Lugari',
          'St. Mary Parish – Shinyalu',
          'Our Lady of Lourdes Parish – Khwisero',
          'St. Augustine Parish – Navakholo'
        ];
      } else if (selectedDiocese == 'Diocese of Kericho') {
        availableParishes = [
          'Christ the King Cathedral Parish – Kericho',
          'St. Michael Parish – Bomet',
          'Holy Family Parish – Sotik',
          'Sacred Heart Parish – Kapkatet',
          'St. Joseph Parish – Litein',
          'Our Lady of Fatima Parish – Roret',
          'St. Mary Parish – Kipkelion',
          'St. Paul Parish – Bureti'
        ];
      } else if (selectedDiocese == 'Diocese of Kitui') {
        availableParishes = ['St. Monica Cathedral', 'Sacred Heart', 'St. Joseph', 'St. Francis Xavier'];
      } else if (selectedDiocese == 'Diocese of Machakos') {
        availableParishes = ['Sacred Heart Cathedral', 'St. Joseph', 'Holy Ghost', 'St. Mary'];
      } else if (selectedDiocese == 'Diocese of Malindi') {
        availableParishes = ['Christ the King Cathedral', 'St. Teresa', 'Sacred Heart', 'Holy Family'];
      } else if (selectedDiocese == 'Diocese of Maralal') {
        availableParishes = ['Our Lady of Fatima Cathedral', 'St. Joseph', 'Sacred Heart', 'Holy Spirit'];
      } else if (selectedDiocese == 'Diocese of Marsabit') {
        availableParishes = ['St. Joseph the Worker Cathedral', 'Sacred Heart', 'St. Mary', 'Holy Cross'];
      } else if (selectedDiocese == 'Diocese of Meru') {
        availableParishes = ['Cathedral of Our Lady of Consolata', 'St. Joseph', 'Sacred Heart', 'Holy Family'];
      } else if (selectedDiocese == 'Diocese of Nakuru') {
        availableParishes = ['Sacred Heart Cathedral', 'St. Christopher', 'St. Joseph', 'Holy Family'];
      } else if (selectedDiocese == 'Diocese of Nyahururu') {
        availableParishes = ['Sacred Heart Cathedral', 'St. Joseph', 'Holy Spirit', 'St. Mary'];
      }
    } else if (selectedCountry == 'Philippines') {
      if (selectedDiocese == 'Archdiocese of Manila') {
        availableParishes = ['Manila Cathedral', 'Binondo Church', 'Malate Church', 'San Agustin Church'];
      } else if (selectedDiocese == 'Archdiocese of Cebu') {
        availableParishes = ['Cebu Metropolitan Cathedral', 'Basilica of Santo Niño', 'Sacred Heart Parish'];
      } else if (selectedDiocese == 'Archdiocese of Davao') {
        availableParishes = ['San Pedro Cathedral', 'Sacred Heart Parish', 'Christ the King'];
      } else if (selectedDiocese == 'Archdiocese of Cagayan de Oro') {
        availableParishes = ['St. Augustine Cathedral', 'Sacred Heart', 'St. Joseph', 'Holy Rosary'];
      } else if (selectedDiocese == 'Archdiocese of Caceres') {
        availableParishes = ['Naga Metropolitan Cathedral', 'Our Lady of Peñafrancia', 'Sacred Heart'];
      } else if (selectedDiocese == 'Archdiocese of Jaro') {
        availableParishes = ['Jaro Metropolitan Cathedral', 'St. Joseph Seminary', 'Sacred Heart'];
      } else if (selectedDiocese == 'Archdiocese of Lipa') {
        availableParishes = ['San Sebastian Cathedral', 'Sacred Heart', 'St. Joseph', 'Our Lady of Peace'];
      } else if (selectedDiocese == 'Archdiocese of Nueva Segovia') {
        availableParishes = ['Vigan Cathedral', 'St. Paul', 'Sacred Heart', 'St. Joseph'];
      } else if (selectedDiocese == 'Diocese of Baguio') {
        availableParishes = ['Our Lady of Atonement Cathedral', 'Sacred Heart', 'St. Joseph', 'Holy Family'];
      } else if (selectedDiocese == 'Diocese of Bacolod') {
        availableParishes = ['San Sebastian Cathedral', 'St. Joseph', 'Sacred Heart', 'Our Lady of Guadalupe'];
      } else if (selectedDiocese == 'Diocese of Dumaguete') {
        availableParishes = ['St. Catherine of Alexandria Cathedral', 'Sacred Heart', 'St. Paul', 'Holy Cross'];
      }
    } else if (selectedCountry == 'Canada') {
      if (selectedDiocese == 'Archdiocese of Toronto') {
        availableParishes = ['St. Michael\'s Cathedral', 'St. Paul\'s Basilica', 'St. Clare of Assisi', 'Holy Rosary'];
      } else if (selectedDiocese == 'Archdiocese of Montreal') {
        availableParishes = ['Mary Queen of the World Cathedral', 'St. Patrick\'s Basilica', 'Notre-Dame Basilica'];
      } else if (selectedDiocese == 'Archdiocese of Vancouver') {
        availableParishes = ['Holy Rosary Cathedral', 'St. Paul\'s Hospital Chapel', 'Sacred Heart'];
      }
    } else if (selectedCountry == 'United Kingdom') {
      if (selectedDiocese == 'Archdiocese of Westminster') {
        availableParishes = ['Westminster Cathedral', 'Brompton Oratory', 'St. James Spanish Place', 'Sacred Heart'];
      } else if (selectedDiocese == 'Archdiocese of Birmingham') {
        availableParishes = ['St. Chad\'s Cathedral', 'Sacred Heart', 'St. Joseph'];
      } else if (selectedDiocese == 'Archdiocese of Liverpool') {
        availableParishes = ['Metropolitan Cathedral of Christ the King', 'Our Lady and St. Nicholas', 'Sacred Heart'];
      }
    } else if (selectedCountry == 'Australia') {
      if (selectedDiocese == 'Archdiocese of Sydney') {
        availableParishes = ['St. Mary\'s Cathedral', 'St. Patrick\'s Church Hill', 'Sacred Heart', 'St. Joseph'];
      } else if (selectedDiocese == 'Archdiocese of Melbourne') {
        availableParishes = ['St. Patrick\'s Cathedral', 'Sacred Heart', 'St. Joseph', 'Holy Family'];
      } else if (selectedDiocese == 'Archdiocese of Brisbane') {
        availableParishes = ['Cathedral of St. Stephen', 'Holy Spirit', 'Sacred Heart', 'St. Mary'];
      }
    } else if (selectedCountry == 'Brazil') {
      if (selectedDiocese == 'Archdiocese of São Paulo') {
        availableParishes = ['Sé Cathedral', 'Basílica de Nossa Senhora da Consolação', 'Igreja do Rosário', 'Basílica de São Bento'];
      } else if (selectedDiocese == 'Archdiocese of Rio de Janeiro') {
        availableParishes = ['Igreja da Candelária', 'Igreja da Glória do Outeiro', 'Nossa Senhora da Penha', 'São Francisco de Paula'];
      } else if (selectedDiocese == 'Archdiocese of Brasília') {
        availableParishes = ['Metropolitan Cathedral of Brasília', 'Nossa Senhora de Fátima', 'São José', 'Sagrado Coração'];
      } else if (selectedDiocese == 'Archdiocese of Salvador') {
        availableParishes = ['Basílica Catedral Primacial', 'Igreja do Senhor do Bonfim', 'Nossa Senhora da Conceição'];
      } else if (selectedDiocese == 'Archdiocese of Belo Horizonte') {
        availableParishes = ['Cathedral of Our Lady of Good Success', 'São José', 'Sagrado Coração', 'Nossa Senhora de Lourdes'];
      } else if (selectedDiocese == 'Archdiocese of Fortaleza') {
        availableParishes = ['Metropolitan Cathedral', 'São José', 'Nossa Senhora de Fátima', 'Sagrado Coração de Jesus'];
      }
    } else if (selectedCountry == 'Italy') {
      if (selectedDiocese == 'Archdiocese of Milan') {
        availableParishes = ['Duomo di Milano', 'Basilica di Sant\'Ambrogio', 'San Lorenzo Maggiore', 'Santa Maria delle Grazie'];
      } else if (selectedDiocese == 'Archdiocese of Rome') {
        availableParishes = ['San Giovanni in Laterano', 'Santa Maria Maggiore', 'San Paolo fuori le Mura', 'Santa Croce'];
      } else if (selectedDiocese == 'Archdiocese of Naples') {
        availableParishes = ['Naples Cathedral', 'Gesù Nuovo', 'San Lorenzo Maggiore', 'Santa Chiara'];
      } else if (selectedDiocese == 'Archdiocese of Florence') {
        availableParishes = ['Florence Cathedral', 'Santa Croce', 'San Lorenzo', 'Santo Spirito'];
      } else if (selectedDiocese == 'Archdiocese of Venice') {
        availableParishes = ['St. Mark\'s Basilica', 'San Giorgio Maggiore', 'Santa Maria della Salute', 'San Polo'];
      } else if (selectedDiocese == 'Archdiocese of Turin') {
        availableParishes = ['Turin Cathedral', 'San Lorenzo', 'Gran Madre di Dio', 'Santa Cristina'];
      }
    } else if (selectedCountry == 'France') {
      if (selectedDiocese == 'Archdiocese of Paris') {
        availableParishes = ['Notre-Dame de Paris', 'Saint-Sulpice', 'Sainte-Chapelle', 'Saint-Germain-des-Prés'];
      } else if (selectedDiocese == 'Archdiocese of Lyon') {
        availableParishes = ['Lyon Cathedral', 'Basilique Notre-Dame de Fourvière', 'Saint-Nizier'];
      } else if (selectedDiocese == 'Archdiocese of Marseille') {
        availableParishes = ['Marseille Cathedral', 'Notre-Dame de la Garde', 'Saint-Victor'];
      }
    } else if (selectedCountry == 'Spain') {
      if (selectedDiocese == 'Archdiocese of Madrid') {
        availableParishes = ['Almudena Cathedral', 'San Jerónimo el Real', 'San Francisco el Grande'];
      } else if (selectedDiocese == 'Archdiocese of Barcelona') {
        availableParishes = ['Barcelona Cathedral', 'Sagrada Família', 'Santa María del Mar'];
      } else if (selectedDiocese == 'Archdiocese of Seville') {
        availableParishes = ['Seville Cathedral', 'Santa María la Blanca', 'San Salvador'];
      }
    } else if (selectedCountry == 'Germany') {
      if (selectedDiocese == 'Archdiocese of Cologne') {
        availableParishes = ['Cologne Cathedral', 'St. Gereon', 'St. Ursula', 'St. Andreas'];
      } else if (selectedDiocese == 'Archdiocese of Munich and Freising') {
        availableParishes = ['Munich Cathedral', 'St. Michael', 'St. Peter', 'Theatinerkirche'];
      }
    } else if (selectedCountry == 'Nigeria') {
      if (selectedDiocese == 'Archdiocese of Lagos') {
        availableParishes = ['Holy Cross Cathedral', 'St. Leo', 'Sacred Heart', 'St. Dominic'];
      } else if (selectedDiocese == 'Archdiocese of Abuja') {
        availableParishes = ['Our Lady Queen of Nigeria Cathedral', 'St. Augustine', 'Sacred Heart'];
      }
    } else if (selectedCountry == 'Tanzania') {
      if (selectedDiocese == 'Archdiocese of Arusha') {
        availableParishes = [
          'St. Thérèse of the Child Jesus Parish – Arusha (Cathedral)',
          'Parish of the Epiphany of the Lord – Burka',
          'Holy Spirit Parish – Ngarenaro',
          'Holy Family Parish – Njiro',
          'St. Joseph Parish – Olasiti',
          'St. Augustine Parish – Sakina',
          'St. Peter the Apostle Parish – Ngaramtoni',
          'St. Paul the Apostle Parish – Usa River',
          'St. John the Baptist Parish – Leguruki',
          'St. Mary Parish – Oldonyosambu',
          'Christ the King Parish – Monduli',
          'St. Charles Lwanga Parish – Mto wa Mbu',
          'St. Francis of Assisi Parish – Karatu',
          'St. John Parish – Loliondo',
          'St. Mark the Evangelist Parish – Endulen',
          'St. Luke the Evangelist Parish – Ngorongoro',
          'Mary Mother of God Parish – Meserani',
          'St. Stephen the Deacon Parish – Kisongo',
          'St. Matthew the Apostle Parish – Ilboru',
          'St. James the Apostle Parish – Muriet',
          'St. Andrew the Apostle Parish – Moshono',
          'St. Thomas the Apostle Parish – Mateves',
          'St. Barnabas Parish – Oljoro',
          'St. Philip the Apostle Parish – Oltoroto',
          'St. Jude Thaddeus Parish – Engutoto',
          'St. Clare Parish – Nduruma',
          'St. Anne Parish – Maji ya Chai',
          'St. Joachim Parish – Nkoaranga',
          'St. Mary Magdalene Parish – Seela',
          'St. Dominic Parish – Losinoni'
        ];
      } else if (selectedDiocese == 'Diocese of Moshi') {
        availableParishes = [
          'Christ the King Cathedral Parish – Moshi',
          'Holy Family Parish – Bomang\'ombe',
          'St. Denis Parish – Areopagita',
          'St. Joseph Parish – Kilema',
          'St. Peter the Apostle Parish – Kibosho',
          'St. Paul the Apostle Parish – Umbwe',
          'St. John the Evangelist Parish – Machame',
          'St. Michael the Archangel Parish – Uru',
          'St. Andrew the Apostle Parish – Mkuu Rombo',
          'St. James the Apostle Parish – Mashati',
          'St. Mary Parish – Marangu',
          'St. Luke the Evangelist Parish – Mwika',
          'St. Stephen Parish – Himo',
          'St. Thomas the Apostle Parish – Kahe',
          'St. Augustine Parish – Kirua Vunjo',
          'St. Francis of Assisi Parish – Siha',
          'St. Charles Lwanga Parish – Sanya Juu',
          'St. Aloysius Gonzaga Parish – Old Moshi',
          'St. Monica Parish – Mabogini',
          'St. Rita Parish – Kiboriloni',
          'St. Cecilia Parish – Rau',
          'St. Agnes Parish – Kiwalani',
          'St. Veronica Parish – Pasua',
          'St. Raphael Parish – Majengo',
          'St. Gabriel Parish – Soweto',
          'St. Benedict Parish – Kirima',
          'St. Ignatius of Loyola Parish – Chekereni',
          'St. Athanasius Parish – Ugweno',
          'St. Bernard Parish – Usseri',
          'St. Cyprian Parish – Keni'
        ];
      } else if (selectedDiocese == 'Archdiocese of Dar-es-Salaam') {
        availableParishes = [
          'St. Joseph\'s Cathedral Parish – Posta',
          'Our Lady of Perpetual Help Parish – Sinza',
          'St. Peter Parish – Oysterbay',
          'St. Anna Parish – Hananasi',
          'St. Martin de Porres Parish – Mwananyamala',
          'St. Maximilian Kolbe Parish – Mwenge',
          'St. Michael Parish – Kawe',
          'St. James Parish – Kibamba',
          'Blessed Sacrament Parish – Makuburi',
          'St. Thomas More Parish – Mbezi Beach',
          'St. Padri Pio Parish – Tabata Kisiwani',
          'St. Maria Magdalena Parish – Kimara Mtoni',
          'St. Yohane XXIII Parish – Kimara Baruti',
          'St. Anthony of Padua Parish – Mbagala',
          'Holy Cross Parish – Kizuiani',
          'St. Gabriel Parish – Mbawala Kuu',
          'St. Francis of Assisi Parish – Majimatitu',
          'Holy Name of Jesus Parish – Kijichi',
          'St. Charles Borromeo Parish – Mbande',
          'Epiphany Parish – Kijichi / Nzasa',
        ];
      } else if (selectedDiocese == 'Diocese of Morogoro') {
        availableParishes = [
          'Holy Family Parish – Mzinga',
          'St. Patrick Cathedral Parish – Morogoro Urban (Cathedral)',
          'St. John the Baptist Parish – Kilosa',
          'Our Lady of Lourdes Parish – Morogoro',
          'St. Anthony of Padua Parish – Mikumi',
          'St. Francis Xavier Parish – Gairo',
          'St. Joseph Parish – Mvomero',
          'St. Theresa Parish – Matombo',
          'St. Vincent de Paul Parish – Bagamoyo area (shared deanery)',
          'Holy Cross Parish – Mlali',
          'St. Michael Parish – Mikese',
          'Christ the King Parish – Mikumi',
          'St. Gabriel Parish – Kilakala',
          'Blessed Sacrament Parish – Mlimani',
          'St. Mary Help of Christians Parish – Matombo',
          'St. Jude Thaddeus Parish – Magubike',
          'St. James Parish – Mtomobo',
          'Sacred Heart Parish – Morogoro Rural',
          'St. Charles Lwanga Parish – Melela',
          'Holy Spirit Parish – Kilombero',
        ];
      } else if (selectedDiocese == 'Diocese of Tanga') {
        availableParishes = [
          'St. Anthony of Padua Cathedral Parish – Tanga',
          'Holy Spirit Parish – Muheza',
          'St. Teresa Parish – Korogwe',
          'St. Joseph Parish – Pangani',
          'St. Mary Parish – Mzingani',
          'St. Peter Parish – Boma',
          'Christ the King Parish – Tanga',
          'St. Augustine Parish – Tanga Rural',
          'St. Paul Parish – Pongwe',
          'Holy Family Parish – Tanga Urban',
          'St. Francis Parish – Soni',
          'St. Michael Parish – Mtimbwani',
          'St. Dominic Parish – Muheza',
          'St. Joseph the Worker – Tanganyika Road',
          'St. Joseph – Marungu',
        ];
      } else if (selectedDiocese == 'Diocese of Ifakara') {
        availableParishes = [
          'St. Patrick Cathedral Parish – Ifakara',
          'Holy Family Parish – Mngeta',
          'St. Joseph Parish – Liwale',
          'Blessed Sacrament Parish – Ulanga',
          'St. Anthony Parish – Milola',
          'St. Mary Parish – Ifakara',
          'St. Francis Parish – Ruaha',
          'St. Peter Parish – Ifakara Rural',
          'St. Teresa Parish – Ifakara South',
          'Holy Ghost Parish – Ifakara North',
        ];
      } else if (selectedDiocese == 'Diocese of Mahenge') {
        availableParishes = [
          'Christ the King Cathedral – Mahenge',
          'St. Joseph Parish – Mahenge',
          'St. Anthony Parish – Mang\'ula',
          'St. Mary Parish – Ifakara Road',
          'St. Theresa Parish – Dakawa',
          'St. Patrick Parish – Mahenge Rural',
          'Holy Family Parish – Mahenge Urban',
          'St. James Parish – Kilosa Road',
          'St. Joseph the Worker – Njombe',
          'St. Peter Parish – Lukenge',
        ];
      } else if (selectedDiocese == 'Diocese of Zanzibar') {
        availableParishes = [
          'St. Joseph\'s Cathedral Parish – Zanzibar',
          'Holy Cross Parish – Pemba',
          'Our Lady of Victory Parish – Zanzibar',
          'St. Peter Parish – Chake Chake (Pemba)',
          'St. Michael Parish – Wete (Pemba)',
          'St. Peter Claver – Zanzibar Town',
          'St. Mary Help of Christians – Bububu',
          'St. Anthony Parish – Kizimbani',
          'St. Francis Parish – Matemwe',
          'St. Theresa Parish – Nungwi',
        ];
      } else if (selectedDiocese == 'Archdiocese of Dodoma') {
        availableParishes = [
          'St. Paul of the Cross Cathedral Parish – Dodoma (Cathedral)',
          'Holy Spirit Parish – Nzuguni',
          'St. Joseph Parish – Makole',
          'St. Peter Claver Parish – Kikuyu South',
          'St. Theresa Parish – Nkuhungu',
          'Holy Family Parish – Majengo',
          'St. Augustine Parish – Zuzu',
          'St. John the Baptist Parish – Msamilo',
          'St. Anthony Parish – Chamwino',
          'St. Francis Parish – Mnyeu',
          'Sacred Heart Parish – Kalenga',
          'St. Michael Parish – Njoro',
          'St. Charles Lwanga Parish – Mnenia',
          'St. Dominic Parish – Nala',
          'Our Lady of Lourdes Parish – Bahi',
          'St. Monica Parish – Mandewa',
          'St. James Parish – Chikola',
          'Epiphany Parish – Mtumba',
          'St. Lawrence Parish – Msanga',
          'St. Jude Thaddeus Parish – Ipala',
        ];
      } else if (selectedDiocese == 'Archdiocese of Mbeya') {
        availableParishes = [
          'St. Anthony of Padua Cathedral Parish – Mbeya (Cathedral)',
          'St. Peter the Apostle Parish – Forest',
          'Holy Cross Parish – Mbalizi',
          'St. Mary Parish – Uzunguni',
          'St. Joseph Parish – Iyunga',
          'St. Paul Parish – Mbalizi Road',
          'St. Francis of Assisi Parish – Tukuyu',
          'St. Augustine Parish – Matema',
          'St. Theresa Parish – Mbeya Kati',
          'Holy Family Parish – Mwaselela',
          'St. Dominic Parish – Ilezi',
          'St. John Bosco Parish – Mbeya',
          'St. Andrew Apostle Parish – Tanangozi',
          'Sacred Heart Parish – Mbeya',
          'St. Michael Parish – Sakina',
          'Our Lady Queen of Peace – Mbeya',
          'St. Charles Lwanga Parish – Mbeya Town',
          'St. James Parish – Mwambenja',
          'St. Anthony Parish – Izazi',
          'Christians on the Way Parish – Mbeya',
        ];
      } else if (selectedDiocese == 'Diocese of Iringa') {
        availableParishes = [
          'St. Patrick Cathedral Parish – Iringa (Cathedral)',
          'Holy Family Parish – Mkwawa',
          'St. Joseph Parish – Lububu',
          'St. Joseph the Worker Parish – Kalenga Road',
          'St. Theresa Parish – Mapanda',
          'St. Mary Parish – Kihesa',
          'St. Peter Parish – Mlandege',
          'St. Anthony Parish – Kitwiru',
          'St. Francis Parish – Ikwete',
          'St. Paul Parish – Nyang\'ombe',
          'Sacred Heart Parish – Iringa Urban',
          'St. Thomas Apostle Parish – Kisawani',
          'St. Charles Lwanga Parish – Iringa Rural',
          'St. Augustine Parish – Mtwivila',
          'St. Benedict Parish – Ngeleli',
          'St. James the Apostle Parish – Matamba',
          'St. Jude Thaddeus Parish – Ipogolo',
          'Holy Spirit Parish – Igumbilo',
        ];
      } else if (selectedDiocese == 'Diocese of Sumbawanga') {
        availableParishes = [
          'Holy Family Cathedral Parish – Sumbawanga (Cathedral)',
          'St. Anthony of Padua Parish – Tunduma',
          'St. Joseph Parish – Mbozi',
          'St. Theresa Parish – Sumbawanga Town',
          'St. Peter Parish – Kupanga',
          'St. Paul Parish – Chato',
          'St. Charles Lwanga Parish – Sumbawanga Rural',
          'St. Francis of Assisi Parish – Nsekela',
          'St. Benedict Parish – Kalambo',
          'St. Augustine Parish – Singida Village (Sumbawanga‑area)',
          'St. Jude Thaddeus Parish – Mpanda Road',
          'Blessed Sacrament Parish – Sumbawanga Urban',
          'Holy Cross Parish – Tangwa',
          'St. Luke Parish – Sikonge',
          'St. Mark Parish – Nyimbili',
          'St. Matthew Parish – Mwisi',
          'Mary Mother of God Parish – Sumbawanga West',
        ];
      } else if (selectedDiocese == 'Archdiocese of Mwanza') {
        availableParishes = [
          'St. Mary\'s Cathedral Parish – Mwanza (Cathedral)',
          'St. Peter the Apostle Parish – Nyamagana',
          'St. Paul the Apostle Parish – Buhongwa',
          'St. Joseph Parish – Mlowo',
          'Holy Family Parish – Kirumba',
          'St. Francis of Assisi Parish – Ilemela',
          'St. Anthony Parish – Sengerema',
          'St. Michael the Archangel Parish – Mwanza City',
          'St. Charles Lwanga Parish – Buhongwa East',
          'St. Theresa Parish – Bukindo',
          'St. Benedict Parish – Mwita',
          'St. Theresa of the Child Jesus Parish – Nyalikungu',
          'St. Augustine Parish – Mwanza Rural',
          'St. John the Evangelist Parish – Igombe',
          'St. Stephen Parish – Nyakato',
          'Sacred Heart Parish – Mwanza South',
          'Blessed Sacrament Parish – Mwanza West',
        ];
      } else if (selectedDiocese == 'Diocese of Bukoba') {
        availableParishes = [
          'Christ the King Cathedral Parish – Bukoba (Cathedral)',
          'St. Theresa Parish – Kyaka',
          'St. Joseph Parish – Bukoba Urban',
          'St. Peter the Apostle Parish – Kabanga',
          'St. Paul Parish – Katoma',
          'St. Francis of Assisi Parish – Kagera Lake Road',
          'Holy Family Parish – Bugene',
          'St. Augustine Parish – Bukoba Rural',
          'St. Mary Parish – Kitale',
          'St. Michael Parish – Bukoba East',
          'St. John the Baptist Parish – Bukoba Town',
          'St. Anthony Parish – Maruku',
          'St. Charles Lwanga Parish – Bukindo',
          'Holy Spirit Parish – Rwentuha',
          'St. Benedict Parish – Bukoba North',
          'Sacred Heart Parish – Bukoba South',
          'St. James Parish – Kiziba',
        ];
      } else if (selectedDiocese == 'Diocese of Geita') {
        availableParishes = [
          'St. Peter Cathedral Parish – Geita (Cathedral)',
          'Holy Family Parish – Geita Town',
          'St. Joseph Parish – Bukombe',
          'St. Mary Parish – Nyankanga',
          'St. Paul Parish – Geita Rural',
          'St. Charles Lwanga Parish – Mbogwe',
          'St. Augustine Parish – Kasamwa',
          'St. Anthony Parish – Bukwimba',
          'St. Francis Parish – Nyamigogo',
          'St. Michael Parish – Nyakahura',
          'St. Theresa Parish – Chitongo',
          'St. John the Baptist Parish – Geita East',
          'St. Benedict Parish – Isaka',
          'St. Jude Thaddeus Parish – Bukwimba South',
          'Sacred Heart Parish – Geita West',
        ];
      } else if (selectedDiocese == 'Diocese of Musoma') {
        availableParishes = [
          'St. Theresa Cathedral Parish – Musoma (Cathedral)',
          'St. Joseph Parish – Musoma Town',
          'Holy Family Parish – Nyakato',
          'St. Mary Parish – Bukumi',
          'St. Peter Parish – Kibeta',
          'St. Paul Parish – Musoma Rural',
          'St. Charles Lwanga Parish – Bunda Road',
          'St. Francis of Assisi Parish – Gwitira',
          'St. Augustine Parish – Kitangiri',
          'St. Anthony Parish – Bugwema',
          'St. Michael Parish – Musoma East',
          'St. John the Baptist Parish – Musoma West',
          'St. Benedict Parish – Nyegina',
          'St. Jude Thaddeus Parish – Bukumi South',
          'Sacred Heart Parish – Musoma North',
        ];
      } else if (selectedDiocese == 'Diocese of Shinyanga') {
        availableParishes = [
          'St. Theresa Cathedral Parish – Shinyanga (Cathedral)',
          'St. Joseph Parish – Shinyanga Town',
          'Holy Family Parish – Nkoland',
          'St. Mary Parish – Mwakitolyo',
          'St. Peter Parish – Buswelu',
          'St. Paul Parish – Shinyanga Rural',
          'St. Augustine Parish – Mwanase',
          'St. Anthony Parish – Mwanga',
          'St. Francis of Assisi Parish – Maseyu',
          'St. Charles Lwanga Parish – Bukomela',
          'St. Michael Parish – Shinyanga West',
          'St. John the Baptist Parish – Shinyanga East',
          'St. Benedict Parish – Mwakitolyo South',
          'St. James Parish – Shinyanga North',
          'Sacred Heart Parish – Mwakitolyo North',
        ];
      } else if (selectedDiocese == 'Diocese of Kahama') {
        availableParishes = [
          'St. Theresa Cathedral Parish – Kahama (Cathedral)',
          'St. Joseph Parish – Kahama Town',
          'Holy Family Parish – Mwendakulima',
          'St. Mary Parish – Nyihogo',
          'St. Peter Parish – Isagehe',
          'St. Paul Parish – Kahama Rural',
          'St. Augustine Parish – Nyasubi',
          'St. Anthony Parish – Kitungwa',
          'St. Francis Parish – Mholeka',
          'St. Charles Lwanga Parish – Kahama East',
          'St. Michael Parish – Kahama West',
          'St. John the Baptist Parish – Bukwimba',
          'St. Benedict Parish – Kitungwa South',
          'St. James Parish – Nyihogo North',
          'Sacred Heart Parish – Kahama North',
        ];
      } else if (selectedDiocese == 'Diocese of Kigoma') {
        availableParishes = [
          'St. Paul Cathedral Parish – Kigoma (Cathedral)',
          'Holy Family Parish – Kigoma Town',
          'St. Joseph Parish – Kasulu',
          'St. Mary Parish – Kigoma Rural',
          'St. Peter Parish – Nyamkolo',
          'St. Francis of Assisi Parish – Ujiji',
          'St. Augustine Parish – Kasekela',
          'St. Anthony Parish – Simbo',
          'St. Michael Parish – Kigoma East',
          'St. Charles Lwanga Parish – Kigoma West',
          'St. Theresa Parish – Kigoma South',
          'St. John the Baptist Parish – Kigoma North',
          'St. Benedict Parish – Kasulu Rural',
          'St. Jude Thaddeus Parish – Kigoma Center',
          'Sacred Heart Parish – Kigoma Urban',
        ];
      } else if (selectedDiocese == 'Diocese of Mpanda') {
        availableParishes = [
          'St. Joseph Cathedral Parish – Mpanda (Cathedral)',
          'St. Mary Parish – Mpanda Town',
          'Holy Family Parish – Mlele',
          'St. Peter Parish – Sitalike',
          'St. Paul Parish – Mpanda Rural',
          'St. Augustine Parish – Kaliua Road',
          'St. Charles Lwanga Parish – Mpanda West',
          'St. Theresa Parish – Mpanda East',
          'St. Anthony Parish – Mpanda North',
          'St. Benedict Parish – Mpanda South',
          'St. Francis Parish – Malambwe',
          'St. Michael Parish – Sitalike South',
          'St. John the Baptist Parish – Mpanda Center',
          'St. Jude Thaddeus Parish – Mpanda Rural',
          'Sacred Heart Parish – Mpanda Urban',
        ];
      } else if (selectedDiocese == 'Diocese of Lindi') {
        availableParishes = [
          'St. Theresa Cathedral Parish – Lindi (Cathedral)',
          'St. Joseph Parish – Lindi Town',
          'Holy Family Parish – Nachingwea Road',
          'St. Mary Parish – Mchinga',
          'St. Peter Parish – Kilwa Road',
          'St. Paul Parish – Lindi Rural',
          'St. Augustine Parish – Lindi West',
          'St. Anthony Parish – Lindi East',
          'St. Francis of Assisi Parish – Mnara',
          'St. Michael Parish – Lindi South',
          'St. Charles Lwanga Parish – Lindi North',
          'St. John the Baptist Parish – Lindi Center',
          'St. Benedict Parish – Nachingwea',
          'St. Jude Thaddeus Parish – Lindi Urban',
          'Sacred Heart Parish – Kilwa South',
        ];
      } else if (selectedDiocese == 'Diocese of Mtwara') {
        availableParishes = [
          'St. Joseph Cathedral Parish – Mtwara (Cathedral)',
          'St. Mary Parish – Mtwara Town',
          'Holy Family Parish – Lukuledi',
          'St. Peter Parish – Masasi Road',
          'St. Paul Parish – Mtwara Rural',
          'St. Augustine Parish – Mtwara East',
          'St. Charles Lwanga Parish – Mtwara West',
          'St. Theresa Parish – Mtwara South',
          'St. Anthony Parish – Mtwara North',
          'St. Francis Parish – Lukuledi East',
          'St. Michael Parish – Mtwara Center',
          'St. John the Baptist Parish – Mtwara Urban',
          'St. Benedict Parish – Mtwara Rural South',
          'St. Jude Thaddeus Parish – Mtwara Rural North',
          'Sacred Heart Parish – Mtwara Coast',
        ];
      } else if (selectedDiocese == 'Diocese of Bunda') {
        availableParishes = [
          'St. Theresa Cathedral Parish – Bunda (Cathedral)',
          'Holy Family Parish – Bunda Town',
          'St. Joseph Parish – Ngula',
          'St. Peter the Apostle Parish – Bukoko',
          'St. Paul Parish – Kakora',
          'St. Mary Parish – Bunda Rural',
          'St. Francis Parish – Nyamuswa',
          'St. Augustine Parish – Masaba',
          'St. Michael Parish – Busisi',
          'St. Charles Lwanga Parish – Nyakasura',
          'St. Anthony Parish – Nyakato',
          'St. John the Baptist Parish – Bunda East',
          'St. Benedict Parish – Nyamirembe',
          'St. Jude Thaddeus Parish – Kagoma',
          'Sacred Heart Parish – Bunda South',
          'St. James Parish – Bukoko North',
        ];
      } else if (selectedDiocese == 'Diocese of Kayanga') {
        availableParishes = [
          'St. Joseph Cathedral Parish – Kayanga (Cathedral)',
          'St. Mary Parish – Kayanga Town',
          'Holy Family Parish – Ruhanga',
          'St. Peter Parish – Kyang\'ombe',
          'St. Paul Parish – Kayanga Rural',
          'St. Francis of Assisi Parish – Bunazi',
          'St. Anthony Parish – Rukarwe',
          'St. Augustine Parish – Muleba Road',
          'St. Michael Parish – Kayanga East',
          'St. Charles Lwanga Parish – Nyakibale',
          'St. Theresa Parish – Kayanga West',
          'St. John the Baptist Parish – Kayanga South',
          'St. Benedict Parish – Bugarika',
          'St. Jude Thaddeus Parish – Nyakahura',
          'Sacred Heart Parish – Rukoma',
        ];
      } else if (selectedDiocese == 'Diocese of Rulenge-Ngara') {
        availableParishes = [
          'St. Theresa Cathedral Parish – Rulenge (Cathedral)',
          'St. Joseph Parish – Ngara Town',
          'Holy Family Parish – Rulenge Rural',
          'St. Mary Parish – Kanyigo',
          'St. Peter Parish – Kibirizi',
          'St. Paul Parish – Muleba Road',
          'St. Augustine Parish – Kishanda',
          'St. Anthony Parish – Bugarama',
          'St. Francis Parish – Nyakibale',
          'St. Michael Parish – Kagera East',
          'St. Charles Lwanga Parish – Ngara Rural',
          'St. John the Baptist Parish – Rulenge West',
          'St. Benedict Parish – Ngara South',
          'St. James Parish – Bukoba Road',
          'Sacred Heart Parish – Rulenge North',
        ];
      }
    }
    
    // If no specific parishes found, provide a helpful message
    if (availableParishes.isEmpty && selectedDiocese.isNotEmpty) {
      if (_isCustomDiocese) {
        // For custom dioceses, provide some generic options
        availableParishes = [
          'Cathedral Parish',
          'St. Mary Parish', 
          'Sacred Heart Parish',
          'St. Joseph Parish',
          'Holy Family Parish'
        ];
      } else {
        // For predefined dioceses without specific parish data, 
        // show a message indicating parish data is being updated
        availableParishes = [
          'Parish data for this diocese is being updated...',
          'Please select "Enter a custom Diocese" to add your specific parish',
          'Or contact support to request parish data for $selectedDiocese'
        ];
      }
    }
    
    return availableParishes;
  }

  // Get filtered parishes based on search text
  List<String> get _filteredParishes {
    final availableParishes = _getAvailableParishes();
    if (_parishSearchController.text.isEmpty) {
      return availableParishes;
    } else {
      return availableParishes.where((parish) {
        return parish
            .toLowerCase()
            .contains(_parishSearchController.text.toLowerCase());
      }).toList();
    }
  }

  @override
  void initState() {
    super.initState();
    // Initialize controllers and state
    _selectedCountry = null;
    _selectedDiocese = null;
    _isCountryDropdownOpen = false;
    _isCustomDiocese = false;
    
  }

  @override
  void dispose() {
    _countrySearchController.dispose();
    _dioceseSearchController.dispose();
    _customDioceseController.dispose();
    super.dispose();
  }
}