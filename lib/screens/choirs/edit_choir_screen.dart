import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/choir_controller.dart';
import '../../models/choir_model.dart';
import '../../services/choir_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/helpers.dart';
import '../../utils/logger.dart';

class EditChoirScreen extends StatefulWidget {

  const EditChoirScreen({
    super.key,
    required this.choir,
  });
  final ChoirModel choir;

  @override
  State<EditChoirScreen> createState() => _EditChoirScreenState();
}

class _EditChoirScreenState extends State<EditChoirScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  final ImagePicker _picker = ImagePicker();
  final ChoirService _choirService = ChoirService();
  File? _selectedImage;
  Uint8List? _webImageBytes;
  String? _currentImageUrl;
  
  // Country search functionality
  final TextEditingController _countrySearchController = TextEditingController();
  String? _selectedCountry;
  bool _isCountryDropdownOpen = false;
  
  // Diocese search functionality
  final TextEditingController _dioceseSearchController = TextEditingController();
  String? _selectedDiocese;
  bool _isDioceseDropdownOpen = false;
  bool _isCustomDiocese = false;
  final TextEditingController _customDioceseController = TextEditingController();
  
  // Parish search functionality
  final TextEditingController _parishSearchController = TextEditingController();
  String? _selectedParish;
  bool _isParishDropdownOpen = false;
  bool _isCustomParish = false;
  final TextEditingController _customParishController = TextEditingController();
  
  // Add controllers for core fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

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

  // Diocese data by country - Only showing major countries with Catholic dioceses
  static const Map<String, List<Map<String, String>>> _diocesesByCountry = {
    'United States': [
      {'name': 'Archdiocese of Atlanta', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Baltimore', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Boston', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Chicago', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Cincinnati', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Denver', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Detroit', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Los Angeles', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Miami', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Milwaukee', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of New Orleans', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of New York', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Philadelphia', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of San Francisco', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Seattle', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of St. Louis', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Washington', 'type': 'Archdiocese'},
    ],
    'Kenya': [
      {'name': 'Archdiocese of Kisumu', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Mombasa', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Nairobi', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Nyeri', 'type': 'Archdiocese'},
      {'name': 'Diocese of Eldoret', 'type': 'Diocese'},
      {'name': 'Diocese of Garissa', 'type': 'Diocese'},
      {'name': 'Diocese of Kakamega', 'type': 'Diocese'},
      {'name': 'Diocese of Kericho', 'type': 'Diocese'},
      {'name': 'Diocese of Kitui', 'type': 'Diocese'},
      {'name': 'Diocese of Machakos', 'type': 'Diocese'},
      {'name': 'Diocese of Malindi', 'type': 'Diocese'},
      {'name': 'Diocese of Marsabit', 'type': 'Diocese'},
      {'name': 'Diocese of Meru', 'type': 'Diocese'},
      {'name': 'Diocese of Nakuru', 'type': 'Diocese'},
    ],
    'Ghana': [
      {'name': 'Archdiocese of Accra', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Cape Coast', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Kumasi', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Tamale', 'type': 'Archdiocese'},
      {'name': 'Diocese of Ho', 'type': 'Diocese'},
      {'name': 'Diocese of Keta-Akatsi', 'type': 'Diocese'},
      {'name': 'Diocese of Koforidua', 'type': 'Diocese'},
      {'name': 'Diocese of Konongo-Mampong', 'type': 'Diocese'},
      {'name': 'Diocese of Obuasi', 'type': 'Diocese'},
      {'name': 'Diocese of Sekondi-Takoradi', 'type': 'Diocese'},
      {'name': 'Diocese of Sunyani', 'type': 'Diocese'},
      {'name': 'Diocese of Wa', 'type': 'Diocese'},
      {'name': 'Diocese of Wiawso', 'type': 'Diocese'},
      {'name': 'Diocese of Yendi', 'type': 'Diocese'},
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
    ],
    'Brazil': [
      {'name': 'Archdiocese of Aparecida', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Brasília', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Fortaleza', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Goiânia', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Olinda and Recife', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Porto Alegre', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Rio de Janeiro', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Salvador da Bahia', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of São Paulo', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of São Sebastião do Rio de Janeiro', 'type': 'Archdiocese'},
    ],
    'Canada': [
      {'name': 'Archdiocese of Edmonton', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Halifax-Yarmouth', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Montreal', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Ottawa', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Quebec', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Toronto', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Vancouver', 'type': 'Archdiocese'},
      {'name': 'Diocese of Calgary', 'type': 'Diocese'},
      {'name': 'Diocese of Hamilton', 'type': 'Diocese'},
      {'name': 'Diocese of London', 'type': 'Diocese'},
      {'name': 'Diocese of Victoria', 'type': 'Diocese'},
    ],
    'United Kingdom': [
      {'name': 'Archdiocese of Birmingham', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Cardiff', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Liverpool', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Westminster', 'type': 'Archdiocese'},
      {'name': 'Diocese of Aberdeen', 'type': 'Diocese'},
      {'name': 'Diocese of Leeds', 'type': 'Diocese'},
      {'name': 'Diocese of Nottingham', 'type': 'Diocese'},
      {'name': 'Diocese of Portsmouth', 'type': 'Diocese'},
    ],
    'Australia': [
      {'name': 'Archdiocese of Adelaide', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Brisbane', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Melbourne', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Perth', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Sydney', 'type': 'Archdiocese'},
      {'name': 'Diocese of Ballarat', 'type': 'Diocese'},
      {'name': 'Diocese of Darwin', 'type': 'Diocese'},
      {'name': 'Diocese of Wollongong', 'type': 'Diocese'},
    ],
    'Philippines': [
      {'name': 'Archdiocese of Cebu', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Davao', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Manila', 'type': 'Archdiocese'},
      {'name': 'Diocese of Antipolo', 'type': 'Diocese'},
      {'name': 'Diocese of Bacolod', 'type': 'Diocese'},
      {'name': 'Diocese of Cubao', 'type': 'Diocese'},
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
      {'name': 'Diocese of Kotido', 'type': 'Diocese'},
      {'name': 'Diocese of Lira', 'type': 'Diocese'},
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
      {'name': 'Diocese of Iringa', 'type': 'Diocese'},
      {'name': 'Diocese of Kigoma', 'type': 'Diocese'},
      {'name': 'Diocese of Kondoa', 'type': 'Diocese'},
      {'name': 'Diocese of Lindi', 'type': 'Diocese'},
      {'name': 'Diocese of Morogoro', 'type': 'Diocese'},
      {'name': 'Diocese of Moshi', 'type': 'Diocese'},
      {'name': 'Diocese of Musoma', 'type': 'Diocese'},
      {'name': 'Diocese of Mtwara', 'type': 'Diocese'},
      {'name': 'Diocese of Shinyanga', 'type': 'Diocese'},
      {'name': 'Diocese of Tanga', 'type': 'Diocese'},
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
    'Ethiopia': [
      {'name': 'Archdiocese of Addis Ababa', 'type': 'Archdiocese'},
      {'name': 'Diocese of Adigrat', 'type': 'Diocese'},
      {'name': 'Diocese of Bahir Dar', 'type': 'Diocese'},
      {'name': 'Diocese of Gambella', 'type': 'Diocese'},
      {'name': 'Diocese of Hosanna', 'type': 'Diocese'},
      {'name': 'Diocese of Jimma', 'type': 'Diocese'},
      {'name': 'Diocese of Meki', 'type': 'Diocese'},
      {'name': 'Diocese of Soddo', 'type': 'Diocese'},
    ],
    'Mexico': [
      {'name': 'Archdiocese of Acapulco', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Guadalajara', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Mexico', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Monterrey', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Puebla de los Ángeles', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Tijuana', 'type': 'Archdiocese'},
      {'name': 'Diocese of Aguascalientes', 'type': 'Diocese'},
      {'name': 'Diocese of Ciudad Juárez', 'type': 'Diocese'},
      {'name': 'Diocese of Cuernavaca', 'type': 'Diocese'},
      {'name': 'Diocese of Querétaro', 'type': 'Diocese'},
      {'name': 'Diocese of Veracruz', 'type': 'Diocese'},
    ],
    'Argentina': [
      {'name': 'Archdiocese of Buenos Aires', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Córdoba', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of La Plata', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Mendoza', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Rosario', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Tucumán', 'type': 'Archdiocese'},
      {'name': 'Diocese of Catamarca', 'type': 'Diocese'},
      {'name': 'Diocese of Jujuy', 'type': 'Diocese'},
      {'name': 'Diocese of Mar del Plata', 'type': 'Diocese'},
      {'name': 'Diocese of Neuquén', 'type': 'Diocese'},
      {'name': 'Diocese of Posadas', 'type': 'Diocese'},
    ],
    'Colombia': [
      {'name': 'Archdiocese of Barranquilla', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Bogotá', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Cali', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Cartagena', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Medellín', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Popayán', 'type': 'Archdiocese'},
      {'name': 'Diocese of Armenia', 'type': 'Diocese'},
      {'name': 'Diocese of Cúcuta', 'type': 'Diocese'},
      {'name': 'Diocese of Pereira', 'type': 'Diocese'},
      {'name': 'Diocese of Valledupar', 'type': 'Diocese'},
    ],
    'Peru': [
      {'name': 'Archdiocese of Arequipa', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Cusco', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Lima', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Piura', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Trujillo', 'type': 'Archdiocese'},
      {'name': 'Diocese of Cajamarca', 'type': 'Diocese'},
      {'name': 'Diocese of Chiclayo', 'type': 'Diocese'},
      {'name': 'Diocese of Chimbote', 'type': 'Diocese'},
      {'name': 'Diocese of Iquitos', 'type': 'Diocese'},
      {'name': 'Diocese of Puno', 'type': 'Diocese'},
    ],
    'Chile': [
      {'name': 'Archdiocese of Antofagasta', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Concepción', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Santiago de Chile', 'type': 'Archdiocese'},
      {'name': 'Diocese of Chillán', 'type': 'Diocese'},
      {'name': 'Diocese of Iquique', 'type': 'Diocese'},
      {'name': 'Diocese of Osorno', 'type': 'Diocese'},
      {'name': 'Diocese of Temuco', 'type': 'Diocese'},
      {'name': 'Diocese of Valparaíso', 'type': 'Diocese'},
    ],
    'Italy': [
      {'name': 'Archdiocese of Bologna', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Firenze', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Milano', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Napoli', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Palermo', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Roma', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Torino', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Venezia', 'type': 'Archdiocese'},
      {'name': 'Diocese of Bergamo', 'type': 'Diocese'},
      {'name': 'Diocese of Brescia', 'type': 'Diocese'},
      {'name': 'Diocese of Como', 'type': 'Diocese'},
      {'name': 'Diocese of Padova', 'type': 'Diocese'},
      {'name': 'Diocese of Verona', 'type': 'Diocese'},
    ],
    'France': [
      {'name': 'Archdiocese of Avignon', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Bordeaux', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Lille', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Lyon', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Marseille', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Paris', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Reims', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Toulouse', 'type': 'Archdiocese'},
      {'name': 'Diocese of Angers', 'type': 'Diocese'},
      {'name': 'Diocese of Chartres', 'type': 'Diocese'},
      {'name': 'Diocese of Metz', 'type': 'Diocese'},
      {'name': 'Diocese of Nice', 'type': 'Diocese'},
      {'name': 'Diocese of Versailles', 'type': 'Diocese'},
    ],
    'Germany': [
      {'name': 'Archdiocese of Berlin', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Freiburg', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Hamburg', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Köln', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of München und Freising', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Paderborn', 'type': 'Archdiocese'},
      {'name': 'Diocese of Aachen', 'type': 'Diocese'},
      {'name': 'Diocese of Augsburg', 'type': 'Diocese'},
      {'name': 'Diocese of Essen', 'type': 'Diocese'},
      {'name': 'Diocese of Münster', 'type': 'Diocese'},
      {'name': 'Diocese of Würzburg', 'type': 'Diocese'},
    ],
    'Spain': [
      {'name': 'Archdiocese of Barcelona', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Granada', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Madrid', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Santiago de Compostela', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Sevilla', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Toledo', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Valencia', 'type': 'Archdiocese'},
      {'name': 'Diocese of Bilbao', 'type': 'Diocese'},
      {'name': 'Diocese of Córdoba', 'type': 'Diocese'},
      {'name': 'Diocese of León', 'type': 'Diocese'},
      {'name': 'Diocese of Málaga', 'type': 'Diocese'},
      {'name': 'Diocese of Salamanca', 'type': 'Diocese'},
    ],
    'Poland': [
      {'name': 'Archdiocese of Gdańsk', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Kraków', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Poznań', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Warszawa', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Wrocław', 'type': 'Archdiocese'},
      {'name': 'Diocese of Kielce', 'type': 'Diocese'},
      {'name': 'Diocese of Opole', 'type': 'Diocese'},
      {'name': 'Diocese of Tarnów', 'type': 'Diocese'},
    ],
    'India': [
      {'name': 'Archdiocese of Bangalore', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Bombay', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Calcutta', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Delhi', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Goa and Daman', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Hyderabad', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Madras and Mylapore', 'type': 'Archdiocese'},
      {'name': 'Diocese of Agra', 'type': 'Diocese'},
      {'name': 'Diocese of Ahmedabad', 'type': 'Diocese'},
      {'name': 'Diocese of Cochin', 'type': 'Diocese'},
      {'name': 'Diocese of Mangalore', 'type': 'Diocese'},
      {'name': 'Diocese of Pune', 'type': 'Diocese'},
    ],
    'Indonesia': [
      {'name': 'Archdiocese of Jakarta', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Medan', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Semarang', 'type': 'Archdiocese'},
      {'name': 'Diocese of Bandung', 'type': 'Diocese'},
      {'name': 'Diocese of Malang', 'type': 'Diocese'},
      {'name': 'Diocese of Purwokerto', 'type': 'Diocese'},
      {'name': 'Diocese of Surabaya', 'type': 'Diocese'},
      {'name': 'Diocese of Yogyakarta', 'type': 'Diocese'},
    ],
    'South Korea': [
      {'name': 'Archdiocese of Seoul', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Kwangju', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Daegu', 'type': 'Archdiocese'},
      {'name': 'Diocese of Busan', 'type': 'Diocese'},
      {'name': 'Diocese of Incheon', 'type': 'Diocese'},
      {'name': 'Diocese of Suwon', 'type': 'Diocese'},
      {'name': 'Diocese of Wonju', 'type': 'Diocese'},
    ],
    'South Africa': [
      {'name': 'Archdiocese of Cape Town', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Durban', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Johannesburg', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Pretoria', 'type': 'Archdiocese'},
      {'name': 'Diocese of Kimberley', 'type': 'Diocese'},
      {'name': 'Diocese of Kokstad', 'type': 'Diocese'},
      {'name': 'Diocese of Port Elizabeth', 'type': 'Diocese'},
      {'name': 'Diocese of Witbank', 'type': 'Diocese'},
    ],
    'Ireland': [
      {'name': 'Archdiocese of Armagh', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Dublin', 'type': 'Archdiocese'},
      {'name': 'Archdiocese of Tuam', 'type': 'Archdiocese'},
      {'name': 'Diocese of Cork and Ross', 'type': 'Diocese'},
      {'name': 'Diocese of Kerry', 'type': 'Diocese'},
      {'name': 'Diocese of Limerick', 'type': 'Diocese'},
      {'name': 'Diocese of Waterford and Lismore', 'type': 'Diocese'},
    ]
  };

  @override
  void initState() {
    super.initState();
    _currentImageUrl = widget.choir.imageUrl;
    _initializeFormData();
  }

  void _initializeFormData() {
    _selectedCountry = widget.choir.country;
    _selectedDiocese = widget.choir.diocese;
    _selectedParish = widget.choir.parish;
    
    // Initialize core field controllers
    _nameController.text = widget.choir.name;
    _descriptionController.text = widget.choir.description;
    
    _countrySearchController.text = widget.choir.country ?? '';
    
    if (widget.choir.diocese != null) {
      final dioceseExists = _diocesesByCountry[widget.choir.country]
          ?.any((d) => d['name'] == widget.choir.diocese) ?? false;
      
      if (dioceseExists) {
        _dioceseSearchController.text = widget.choir.diocese!;
      } else {
        _isCustomDiocese = true;
        _customDioceseController.text = widget.choir.diocese!;
      }
    }
    
    if (widget.choir.parish != null) {
      _isCustomParish = true;
      _customParishController.text = widget.choir.parish!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Choir'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Consumer2<ChoirController, AuthController>(
          builder: (context, choirController, authController, child) {
            return FormBuilder(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildImagePicker(),
                  const SizedBox(height: 20),
                  _buildNameField(),
                  const SizedBox(height: 16),
                  _buildDescriptionField(),
                  const SizedBox(height: 16),
                  _buildLocationFields(),
                  const SizedBox(height: 20),
                  _buildActionButtons(choirController),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(60),
            border: Border.all(color: AppColors.primary, width: 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(58),
            child: _getImageWidget(),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _pickImage,
          icon: const Icon(Icons.camera_alt),
          label: const Text('Change Image'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondary,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _getImageWidget() {
    if (_webImageBytes != null) {
      return Image.memory(
        _webImageBytes!,
        fit: BoxFit.cover,
      );
    } else if (_selectedImage != null) {
      return Image.file(
        _selectedImage!,
        fit: BoxFit.cover,
      );
    } else if (_currentImageUrl != null && _currentImageUrl!.isNotEmpty) {
      return Image.network(
        _currentImageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.music_note, size: 50, color: Colors.grey);
        },
      );
    } else {
      return const Icon(Icons.music_note, size: 50, color: Colors.grey);
    }
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: const InputDecoration(
        labelText: 'Choir Name',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.music_note),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Choir name is required';
        }
        return null;
      },
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: const InputDecoration(
        labelText: 'Description',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.description),
      ),
      maxLines: 3,
      maxLength: 500,
      validator: (value) {
        if (value != null && value.length > 500) {
          return 'Description must be less than 500 characters';
        }
        return null;
      },
    );
  }

  Widget _buildLocationFields() {
    return Column(
      children: [
        _buildCountryDropdown(),
        if (_selectedCountry != null) ...[
          const SizedBox(height: 16),
          _buildDioceseDropdown(),
        ],
        const SizedBox(height: 16),
        _buildParishField(),
      ],
    );
  }

  Widget _buildCountryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _countrySearchController,
          decoration: InputDecoration(
            labelText: 'Country',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.public),
            suffixIcon: IconButton(
              icon: Icon(_isCountryDropdownOpen 
                  ? Icons.expand_less 
                  : Icons.expand_more),
              onPressed: () {
                setState(() {
                  _isCountryDropdownOpen = !_isCountryDropdownOpen;
                });
              },
            ),
          ),
          onTap: () {
            setState(() {
              _isCountryDropdownOpen = true;
            });
          },
          onChanged: (value) {
            setState(() {
              _isCountryDropdownOpen = true;
            });
          },
        ),
        if (_isCountryDropdownOpen)
          Container(
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(5),
            ),
            child: ListView.builder(
              itemCount: _getFilteredCountries().length,
              itemBuilder: (context, index) {
                final country = _getFilteredCountries()[index];
                return ListTile(
                  leading: Text(country['flag']!, style: const TextStyle(fontSize: 20)),
                  title: Text(country['name']!),
                  onTap: () {
                    setState(() {
                      _selectedCountry = country['name'];
                      _countrySearchController.text = country['name']!;
                      _isCountryDropdownOpen = false;
                      _selectedDiocese = null;
                      _dioceseSearchController.clear();
                      _customDioceseController.clear();
                      _selectedParish = null;
                      _parishSearchController.clear();
                      _customParishController.clear();
                      _isCustomDiocese = false;
                      _isCustomParish = false;
                    });
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildDioceseDropdown() {
    final dioceses = _diocesesByCountry[_selectedCountry] ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!_isCustomDiocese)
          TextFormField(
            controller: _dioceseSearchController,
            decoration: InputDecoration(
              labelText: 'Diocese/Archdiocese',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.account_balance),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      setState(() {
                        _isCustomDiocese = true;
                        _dioceseSearchController.clear();
                        _selectedDiocese = null;
                      });
                    },
                    tooltip: 'Add Custom Diocese',
                  ),
                  IconButton(
                    icon: Icon(_isDioceseDropdownOpen 
                        ? Icons.expand_less 
                        : Icons.expand_more),
                    onPressed: () {
                      setState(() {
                        _isDioceseDropdownOpen = !_isDioceseDropdownOpen;
                      });
                    },
                  ),
                ],
              ),
            ),
            onTap: () {
              setState(() {
                _isDioceseDropdownOpen = true;
              });
            },
            onChanged: (value) {
              setState(() {
                _isDioceseDropdownOpen = true;
              });
            },
          ),
        if (_isCustomDiocese)
          TextFormField(
            controller: _customDioceseController,
            decoration: InputDecoration(
              labelText: 'Custom Diocese/Archdiocese',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.account_balance),
              suffixIcon: IconButton(
                icon: const Icon(Icons.list),
                onPressed: () {
                  setState(() {
                    _isCustomDiocese = false;
                    _customDioceseController.clear();
                  });
                },
                tooltip: 'Select from List',
              ),
            ),
            onChanged: (value) {
              _selectedDiocese = value;
            },
          ),
        if (_isDioceseDropdownOpen && !_isCustomDiocese && dioceses.isNotEmpty)
          Container(
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(5),
            ),
            child: ListView.builder(
              itemCount: _getFilteredDioceses().length,
              itemBuilder: (context, index) {
                final diocese = _getFilteredDioceses()[index];
                return ListTile(
                  title: Text(diocese['name']!),
                  subtitle: Text(diocese['type']!),
                  onTap: () {
                    setState(() {
                      _selectedDiocese = diocese['name'];
                      _dioceseSearchController.text = diocese['name']!;
                      _isDioceseDropdownOpen = false;
                      _selectedParish = null;
                      _parishSearchController.clear();
                      _customParishController.clear();
                      _isCustomParish = false;
                      _isParishDropdownOpen = false;
                    });
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildParishField() {
    final availableParishes = _getAvailableParishes();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!_isCustomParish)
          TextFormField(
            controller: _parishSearchController,
            decoration: InputDecoration(
              labelText: 'Parish (Optional)',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.church),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (availableParishes.isNotEmpty)
                    IconButton(
                      icon: Icon(_isParishDropdownOpen 
                          ? Icons.expand_less 
                          : Icons.expand_more),
                      onPressed: () {
                        setState(() {
                          _isParishDropdownOpen = !_isParishDropdownOpen;
                        });
                      },
                    ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      setState(() {
                        _isCustomParish = true;
                        _parishSearchController.clear();
                      });
                    },
                    tooltip: 'Add Custom Parish',
                  ),
                ],
              ),
            ),
            onTap: () {
              if (availableParishes.isNotEmpty) {
                setState(() {
                  _isParishDropdownOpen = true;
                });
              }
            },
            onChanged: (value) {
              setState(() {
                _selectedParish = value.isEmpty ? null : value;
                if (availableParishes.isNotEmpty) {
                  _isParishDropdownOpen = true;
                }
              });
            },
            validator: (value) {
              // Parish is optional, so no validation needed
              return null;
            },
          ),
        if (!_isCustomParish && _isParishDropdownOpen && availableParishes.isNotEmpty)
          Container(
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(5),
            ),
            child: ListView.builder(
              itemCount: availableParishes.length,
              itemBuilder: (context, index) {
                final parish = availableParishes[index];
                final isMessage = parish.contains('Parish data for this diocese') || 
                                parish.contains('Please select') || 
                                parish.contains('Or contact support');
                
                return ListTile(
                  leading: Icon(isMessage ? Icons.info : Icons.church),
                  title: Text(
                    parish,
                    style: TextStyle(
                      color: isMessage ? Colors.blue[600] : null,
                      fontStyle: isMessage ? FontStyle.italic : null,
                    ),
                  ),
                  enabled: !isMessage,
                  onTap: isMessage ? null : () {
                    setState(() {
                      _selectedParish = parish;
                      _parishSearchController.text = parish;
                      _isParishDropdownOpen = false;
                    });
                  },
                );
              },
            ),
          ),
        if (_isCustomParish)
          TextFormField(
            controller: _customParishController,
            decoration: InputDecoration(
              labelText: 'Parish Name',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.church),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  setState(() {
                    _isCustomParish = false;
                    _customParishController.clear();
                    _selectedParish = null;
                  });
                },
                tooltip: 'Clear Parish',
              ),
            ),
            onChanged: (value) {
              _selectedParish = value.isEmpty ? null : value;
            },
            validator: (value) {
              // Parish is optional, so no validation needed
              return null;
            },
          ),
      ],
    );
  }

  Widget _buildActionButtons(ChoirController choirController) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: choirController.isLoading 
                ? null 
                : () => _updateChoir(choirController),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: choirController.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Update Choir'),
          ),
        ),
      ],
    );
  }

  List<Map<String, String>> _getFilteredCountries() {
    if (_countrySearchController.text.isEmpty) {
      return _countries;
    }
    
    return _countries.where((country) {
      return country['name']!
          .toLowerCase()
          .contains(_countrySearchController.text.toLowerCase());
    }).toList();
  }

  List<Map<String, String>> _getFilteredDioceses() {
    final dioceses = _diocesesByCountry[_selectedCountry] ?? [];
    
    if (_dioceseSearchController.text.isEmpty) {
      return dioceses;
    }
    
    return dioceses.where((diocese) {
      return diocese['name']!
          .toLowerCase()
          .contains(_dioceseSearchController.text.toLowerCase());
    }).toList();
  }

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
      } else {
        // For predefined dioceses without specific parish data, 
        // show a message indicating parish data is being updated
        availableParishes = [
          'Parish data for this diocese is being updated...',
          'Please select "Enter a custom Diocese" to add your specific parish',
          'Or contact support to request parish data for $selectedDiocese'
        ];
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
      } else {
        availableParishes = [
          'Parish data for this diocese is being updated...',
          'Please select "Enter a custom Diocese" to add your specific parish',
          'Or contact support to request parish data for $selectedDiocese'
        ];
      }
    } else if (selectedCountry == 'Kenya') {
      if (selectedDiocese == 'Roman Catholic Archdiocese of Nairobi') {
        availableParishes = [
          'Holy Family Cathedral – Nairobi',
          'St. Peter Claver Parish',
          'Sacred Heart Parish – Nairobi',
          'Christ the King Parish – Nairobi',
          'Our Lady of Victories Parish'
        ];
      } else if (selectedDiocese == 'Roman Catholic Archdiocese of Kisumu') {
        availableParishes = [
          'Our Lady of Victories Cathedral – Kisumu',
          'Sacred Heart Parish – Kisumu',
          'St. Theresa Parish – Kisumu'
        ];
      } else if (selectedDiocese == 'Roman Catholic Archdiocese of Mombasa') {
        availableParishes = [
          'Holy Ghost Cathedral – Mombasa',
          'Sacred Heart Parish – Mombasa',
          'St. Teresa Parish – Mombasa'
        ];
      } else {
        availableParishes = [
          'Parish data for this diocese is being updated...',
          'Please select "Enter a custom Diocese" to add your specific parish',
          'Or contact support to request parish data for $selectedDiocese'
        ];
      }
    } else if (selectedCountry == 'Nigeria') {
      if (selectedDiocese == 'Roman Catholic Archdiocese of Lagos') {
        availableParishes = [
          'Holy Cross Cathedral – Lagos',
          'St. Dominic Parish – Yaba',
          'Sacred Heart Parish – Lagos',
          'Christ the King Parish – Lagos'
        ];
      } else if (selectedDiocese == 'Roman Catholic Archdiocese of Abuja') {
        availableParishes = [
          'Our Lady Queen of Nigeria Pro-Cathedral',
          'Sacred Heart Parish – Abuja',
          'St. Murumba Parish – Abuja'
        ];
      } else {
        availableParishes = [
          'Parish data for this diocese is being updated...',
          'Please select "Enter a custom Diocese" to add your specific parish',
          'Or contact support to request parish data for $selectedDiocese'
        ];
      }
    } else if (selectedCountry == 'Uganda') {
      if (selectedDiocese == 'Archdiocese of Kampala') {
        availableParishes = [
          'St. Mary\'s Cathedral – Kampala',
          'Christ the King Parish – Kampala',
          'Sacred Heart Parish – Kampala',
          'St. Augustine Parish – Kampala',
          'Holy Family Parish – Kampala'
        ];
      } else if (selectedDiocese == 'Archdiocese of Gulu') {
        availableParishes = [
          'Sacred Heart Cathedral – Gulu',
          'St. Joseph Parish – Gulu',
          'St. Monica Parish – Gulu'
        ];
      } else {
        availableParishes = [
          'Parish data for this diocese is being updated...',
          'Please select "Enter a custom Diocese" to add your specific parish',
          'Or contact support to request parish data for $selectedDiocese'
        ];
      }
    } else if (selectedCountry == 'Tanzania') {
      if (selectedDiocese == 'Archdiocese of Dar-es-Salaam') {
        availableParishes = [
          'St. Joseph Cathedral – Dar es Salaam',
          'Sacred Heart Parish – Dar es Salaam',
          'St. Peter Parish – Dar es Salaam',
          'Holy Cross Parish – Dar es Salaam'
        ];
      } else if (selectedDiocese == 'Archdiocese of Arusha') {
        availableParishes = [
          'St. Teresa Cathedral – Arusha',
          'St. Joseph Parish – Arusha',
          'Sacred Heart Parish – Arusha'
        ];
      } else {
        availableParishes = [
          'Parish data for this diocese is being updated...',
          'Please select "Enter a custom Diocese" to add your specific parish',
          'Or contact support to request parish data for $selectedDiocese'
        ];
      }
    } else if (selectedCountry == 'Rwanda') {
      if (selectedDiocese == 'Archdiocese of Kigali') {
        availableParishes = [
          'Sainte-Famille Cathedral – Kigali',
          'St. Michel Parish – Kigali',
          'Sacred Heart Parish – Kigali',
          'St. Paul Parish – Kigali'
        ];
      } else {
        availableParishes = [
          'Parish data for this diocese is being updated...',
          'Please select "Enter a custom Diocese" to add your specific parish',
          'Or contact support to request parish data for $selectedDiocese'
        ];
      }
    } else if (selectedCountry == 'Ethiopia') {
      if (selectedDiocese == 'Archdiocese of Addis Ababa') {
        availableParishes = [
          'Holy Trinity Cathedral – Addis Ababa',
          'St. Joseph Parish – Addis Ababa',
          'Sacred Heart Parish – Addis Ababa'
        ];
      } else {
        availableParishes = [
          'Parish data for this diocese is being updated...',
          'Please select "Enter a custom Diocese" to add your specific parish',
          'Or contact support to request parish data for $selectedDiocese'
        ];
      }
    } else if (selectedCountry == 'Mexico') {
      if (selectedDiocese == 'Archdiocese of Mexico') {
        availableParishes = [
          'Metropolitan Cathedral – Mexico City',
          'Basilica of Our Lady of Guadalupe',
          'Sacred Heart Parish – Mexico City',
          'San José Parish – Mexico City'
        ];
      } else if (selectedDiocese == 'Archdiocese of Guadalajara') {
        availableParishes = [
          'Cathedral of Guadalajara',
          'Sanctuary of Our Lady of Zapopan',
          'Sacred Heart Parish – Guadalajara',
          'San Juan de Dios Parish'
        ];
      } else {
        availableParishes = [
          'Parish data for this diocese is being updated...',
          'Please select "Enter a custom Diocese" to add your specific parish',
          'Or contact support to request parish data for $selectedDiocese'
        ];
      }
    } else if (selectedCountry == 'Argentina') {
      if (selectedDiocese == 'Archdiocese of Buenos Aires') {
        availableParishes = [
          'Metropolitan Cathedral – Buenos Aires',
          'San Ignacio Parish',
          'Sacred Heart Parish – Buenos Aires',
          'San Francisco Parish'
        ];
      } else {
        availableParishes = [
          'Parish data for this diocese is being updated...',
          'Please select "Enter a custom Diocese" to add your specific parish',
          'Or contact support to request parish data for $selectedDiocese'
        ];
      }
    } else if (selectedCountry == 'Colombia') {
      if (selectedDiocese == 'Archdiocese of Bogotá') {
        availableParishes = [
          'Primatial Cathedral – Bogotá',
          'Sacred Heart Parish – Bogotá',
          'San Ignacio Parish',
          'La Candelaria Parish'
        ];
      } else {
        availableParishes = [
          'Parish data for this diocese is being updated...',
          'Please select "Enter a custom Diocese" to add your specific parish',
          'Or contact support to request parish data for $selectedDiocese'
        ];
      }
    } else if (selectedCountry == 'Italy') {
      if (selectedDiocese == 'Archdiocese of Roma') {
        availableParishes = [
          'St. John Lateran – Rome',
          'St. Peter\'s Basilica',
          'St. Mary Major',
          'St. Paul Outside the Walls',
          'Santa Maria in Trastevere'
        ];
      } else if (selectedDiocese == 'Archdiocese of Milano') {
        availableParishes = [
          'Milan Cathedral',
          'Sant\'Ambrogio Basilica',
          'San Lorenzo Maggiore',
          'Santa Maria delle Grazie'
        ];
      } else {
        availableParishes = [
          'Parish data for this diocese is being updated...',
          'Please select "Enter a custom Diocese" to add your specific parish',
          'Or contact support to request parish data for $selectedDiocese'
        ];
      }
    } else if (selectedCountry == 'France') {
      if (selectedDiocese == 'Archdiocese of Paris') {
        availableParishes = [
          'Notre-Dame Cathedral',
          'Sainte-Chapelle',
          'Saint-Sulpice',
          'Sacred Heart Basilica',
          'Saint-Germain-des-Prés'
        ];
      } else {
        availableParishes = [
          'Parish data for this diocese is being updated...',
          'Please select "Enter a custom Diocese" to add your specific parish',
          'Or contact support to request parish data for $selectedDiocese'
        ];
      }
    } else if (selectedCountry == 'Spain') {
      if (selectedDiocese == 'Archdiocese of Madrid') {
        availableParishes = [
          'Almudena Cathedral – Madrid',
          'San Isidro Church',
          'Sacred Heart Parish – Madrid',
          'San Francisco el Grande'
        ];
      } else {
        availableParishes = [
          'Parish data for this diocese is being updated...',
          'Please select "Enter a custom Diocese" to add your specific parish',
          'Or contact support to request parish data for $selectedDiocese'
        ];
      }
    } else if (selectedCountry == 'India') {
      if (selectedDiocese == 'Archdiocese of Bombay') {
        availableParishes = [
          'Holy Name Cathedral – Mumbai',
          'Sacred Heart Parish – Mumbai',
          'St. Michael\'s Church',
          'Our Lady of the Mount'
        ];
      } else if (selectedDiocese == 'Archdiocese of Delhi') {
        availableParishes = [
          'Sacred Heart Cathedral – New Delhi',
          'St. Columba\'s Church',
          'Sacred Heart Parish – Delhi'
        ];
      } else {
        availableParishes = [
          'Parish data for this diocese is being updated...',
          'Please select "Enter a custom Diocese" to add your specific parish',
          'Or contact support to request parish data for $selectedDiocese'
        ];
      }
    } else if (selectedCountry == 'Indonesia') {
      if (selectedDiocese == 'Archdiocese of Jakarta') {
        availableParishes = [
          'Cathedral of Our Lady of the Assumption – Jakarta',
          'St. Mary of Fatima Parish',
          'Sacred Heart Parish – Jakarta',
          'St. Francis Xavier Parish'
        ];
      } else {
        availableParishes = [
          'Parish data for this diocese is being updated...',
          'Please select "Enter a custom Diocese" to add your specific parish',
          'Or contact support to request parish data for $selectedDiocese'
        ];
      }
    } else if (selectedCountry == 'South Korea') {
      if (selectedDiocese == 'Archdiocese of Seoul') {
        availableParishes = [
          'Myeongdong Cathedral – Seoul',
          'Sacred Heart Parish – Seoul',
          'St. Mary\'s Parish – Seoul',
          'Holy Family Parish'
        ];
      } else {
        availableParishes = [
          'Parish data for this diocese is being updated...',
          'Please select "Enter a custom Diocese" to add your specific parish',
          'Or contact support to request parish data for $selectedDiocese'
        ];
      }
    } else if (selectedCountry == 'South Africa') {
      if (selectedDiocese == 'Archdiocese of Cape Town') {
        availableParishes = [
          'St. Mary\'s Cathedral – Cape Town',
          'Sacred Heart Parish – Cape Town',
          'St. Joseph Parish',
          'Holy Trinity Parish'
        ];
      } else if (selectedDiocese == 'Archdiocese of Johannesburg') {
        availableParishes = [
          'Christ the King Cathedral – Johannesburg',
          'Sacred Heart Parish – Johannesburg',
          'St. Peter Parish',
          'Holy Family Parish'
        ];
      } else {
        availableParishes = [
          'Parish data for this diocese is being updated...',
          'Please select "Enter a custom Diocese" to add your specific parish',
          'Or contact support to request parish data for $selectedDiocese'
        ];
      }
    } else if (selectedCountry == 'Ireland') {
      if (selectedDiocese == 'Archdiocese of Dublin') {
        availableParishes = [
          'St. Mary\'s Pro-Cathedral – Dublin',
          'Sacred Heart Parish – Dublin',
          'St. Patrick\'s Cathedral',
          'Christ Church Cathedral',
          'St. Teresa\'s Parish'
        ];
      } else if (selectedDiocese == 'Archdiocese of Armagh') {
        availableParishes = [
          'St. Patrick\'s Cathedral – Armagh',
          'Sacred Heart Parish – Armagh',
          'St. Malachy\'s Parish'
        ];
      } else {
        availableParishes = [
          'Parish data for this diocese is being updated...',
          'Please select "Enter a custom Diocese" to add your specific parish',
          'Or contact support to request parish data for $selectedDiocese'
        ];
      }
    } else if (selectedCountry == 'Canada') {
      if (selectedDiocese == 'Archdiocese of Toronto') {
        availableParishes = [
          'St. Michael\'s Cathedral – Toronto',
          'Sacred Heart Parish – Toronto',
          'St. Paul\'s Basilica',
          'Holy Family Parish'
        ];
      } else if (selectedDiocese == 'Archdiocese of Montreal') {
        availableParishes = [
          'Mary, Queen of the World Cathedral – Montreal',
          'St. Patrick\'s Basilica',
          'Sacred Heart Parish – Montreal',
          'Notre-Dame Basilica'
        ];
      } else {
        availableParishes = [
          'Parish data for this diocese is being updated...',
          'Please select "Enter a custom Diocese" to add your specific parish',
          'Or contact support to request parish data for $selectedDiocese'
        ];
      }
    } else if (selectedCountry == 'Australia') {
      if (selectedDiocese == 'Archdiocese of Sydney') {
        availableParishes = [
          'St. Mary\'s Cathedral – Sydney',
          'Sacred Heart Parish – Sydney',
          'St. Patrick\'s Parish',
          'Holy Family Parish'
        ];
      } else if (selectedDiocese == 'Archdiocese of Melbourne') {
        availableParishes = [
          'St. Patrick\'s Cathedral – Melbourne',
          'Sacred Heart Parish – Melbourne',
          'St. Mary\'s Parish',
          'Holy Trinity Parish'
        ];
      } else {
        availableParishes = [
          'Parish data for this diocese is being updated...',
          'Please select "Enter a custom Diocese" to add your specific parish',
          'Or contact support to request parish data for $selectedDiocese'
        ];
      }
    } else if (selectedCountry == 'Germany') {
      if (selectedDiocese == 'Archdiocese of Köln') {
        availableParishes = [
          'Cologne Cathedral',
          'Sacred Heart Parish – Cologne',
          'St. Gereon\'s Basilica',
          'Great St. Martin Church'
        ];
      } else {
        availableParishes = [
          'Parish data for this diocese is being updated...',
          'Please select "Enter a custom Diocese" to add your specific parish',
          'Or contact support to request parish data for $selectedDiocese'
        ];
      }
    } else if (selectedCountry == 'Poland') {
      if (selectedDiocese == 'Archdiocese of Kraków') {
        availableParishes = [
          'Wawel Cathedral – Kraków',
          'Sacred Heart Parish – Kraków',
          'St. Mary\'s Basilica',
          'St. Florian\'s Parish'
        ];
      } else {
        availableParishes = [
          'Parish data for this diocese is being updated...',
          'Please select "Enter a custom Diocese" to add your specific parish',
          'Or contact support to request parish data for $selectedDiocese'
        ];
      }
    } else {
      // For countries without specific parish data
      availableParishes = [
        'Parish data for this diocese is being updated...',
        'Please select "Enter a custom Diocese" to add your specific parish',
        'Or contact support to request parish data for $selectedDiocese'
      ];
    }
    
    return availableParishes;
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 500,
        maxHeight: 500,
      );
      
      if (image != null) {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          setState(() {
            _webImageBytes = bytes;
            _selectedImage = null;
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
          SnackBar(
            content: Text('Error picking image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateChoir(ChoirController choirController) async {
    try {
      // Validate required fields directly
      if (_nameController.text.trim().isEmpty) {
        Helpers.showErrorSnackbar('Choir name is required');
        return;
      }
      
      Logger.debug('Original choir name: ${widget.choir.name}');
      Logger.debug('New name from controller: ${_nameController.text}');
      Logger.debug('Description controller: ${_descriptionController.text}');
      
      final updatedChoir = widget.choir.copyWith(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        updatedAt: DateTime.now(), // Set current time for update timestamp
        country: _selectedCountry,
        diocese: _isCustomDiocese ? _customDioceseController.text : _selectedDiocese,
        parish: _isCustomParish ? _customParishController.text : _selectedParish,
      );
      
      Logger.debug('Updated choir name: ${updatedChoir.name}');
      
      String? imageUrl = _currentImageUrl;
      
      // Upload new image if one was selected
      if (_webImageBytes != null || _selectedImage != null) {
        Logger.debug('Uploading new choir image...');
        try {
          if (kIsWeb && _webImageBytes != null) {
            // For web, we need to create a temporary XFile from bytes
            final tempFile = XFile.fromData(
              _webImageBytes!,
              name: 'choir_image_${widget.choir.id}.jpg',
              mimeType: 'image/jpeg',
            );
            imageUrl = await _choirService.uploadChoirImage(widget.choir.id, tempFile);
          } else if (_selectedImage != null) {
            // For mobile platforms
            imageUrl = await _choirService.uploadChoirImageFromFile(widget.choir.id, _selectedImage!);
          }
          
          if (imageUrl != null) {
            Logger.info('Image uploaded successfully: $imageUrl');
            setState(() {
              _currentImageUrl = imageUrl;
            });
          }
        } catch (e) {
          Logger.error('Image upload failed', e);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Image upload failed: $e'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          // Continue with choir update even if image upload fails
        }
      }
      
      final success = await choirController.updateChoir(
        updatedChoir.copyWith(imageUrl: imageUrl),
      );
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Choir updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(choirController.errorMessage ?? 'Failed to update choir'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _countrySearchController.dispose();
    _dioceseSearchController.dispose();
    _customDioceseController.dispose();
    _parishSearchController.dispose();
    _customParishController.dispose();
    super.dispose();
  }
}