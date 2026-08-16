// All Indian states & union territories mapped to their major cities.
// Used to power cascading State -> City dropdowns anywhere in the app.

const Map<String, List<String>> indiaStatesAndCities = {
  'Andhra Pradesh': [
    'Visakhapatnam', 'Vijayawada', 'Guntur', 'Nellore', 'Kurnool',
    'Rajahmundry', 'Tirupati', 'Kadapa', 'Kakinada', 'Anantapur',
    'Eluru', 'Ongole', 'Chittoor', 'Srikakulam', 'Vizianagaram',
  ],
  'Arunachal Pradesh': [
    'Itanagar', 'Naharlagun', 'Pasighat', 'Tawang', 'Ziro', 'Bomdila',
  ],
  'Assam': [
    'Guwahati', 'Silchar', 'Dibrugarh', 'Jorhat', 'Nagaon', 'Tinsukia',
    'Tezpur', 'Karimganj', 'Sivasagar', 'Bongaigaon',
  ],
  'Bihar': [
    'Patna', 'Gaya', 'Bhagalpur', 'Muzaffarpur', 'Purnia', 'Darbhanga',
    'Bihar Sharif', 'Arrah', 'Begusarai', 'Chapra', 'Katihar', 'Munger',
  ],
  'Chhattisgarh': [
    'Raipur', 'Bhilai', 'Bilaspur', 'Korba', 'Durg', 'Rajnandgaon',
    'Jagdalpur', 'Ambikapur', 'Raigarh',
  ],
  'Goa': [
    'Panaji', 'Margao', 'Vasco da Gama', 'Mapusa', 'Ponda', 'Bicholim',
  ],
  'Gujarat': [
    'Ahmedabad', 'Surat', 'Vadodara', 'Rajkot', 'Bhavnagar', 'Jamnagar',
    'Gandhinagar', 'Junagadh', 'Anand', 'Nadiad', 'Morbi', 'Mehsana',
    'Bharuch', 'Vapi', 'Navsari',
  ],
  'Haryana': [
    'Gurugram', 'Faridabad', 'Panipat', 'Ambala', 'Karnal', 'Hisar',
    'Rohtak', 'Sonipat', 'Yamunanagar', 'Panchkula', 'Bhiwani', 'Sirsa',
  ],
  'Himachal Pradesh': [
    'Shimla', 'Manali', 'Dharamshala', 'Solan', 'Mandi', 'Kullu',
    'Una', 'Bilaspur', 'Hamirpur', 'Chamba',
  ],
  'Jharkhand': [
    'Ranchi', 'Jamshedpur', 'Dhanbad', 'Bokaro', 'Deoghar', 'Hazaribagh',
    'Giridih', 'Ramgarh',
  ],
  'Karnataka': [
    'Bengaluru', 'Mysuru', 'Hubballi', 'Mangaluru', 'Belagavi',
    'Kalaburagi', 'Davanagere', 'Ballari', 'Shivamogga', 'Tumakuru',
    'Udupi', 'Hassan', 'Bidar', 'Chikkamagaluru',
  ],
  'Kerala': [
    'Thiruvananthapuram', 'Kochi', 'Kozhikode', 'Thrissur', 'Kollam',
    'Kannur', 'Alappuzha', 'Palakkad', 'Malappuram', 'Kottayam',
    'Idukki', 'Wayanad',
  ],
  'Madhya Pradesh': [
    'Bhopal', 'Indore', 'Gwalior', 'Jabalpur', 'Ujjain', 'Sagar',
    'Dewas', 'Satna', 'Ratlam', 'Rewa', 'Katni', 'Singrauli',
  ],
  'Maharashtra': [
    'Mumbai', 'Pune', 'Nagpur', 'Nashik', 'Thane', 'Aurangabad',
    'Solapur', 'Kolhapur', 'Amravati', 'Navi Mumbai', 'Sangli',
    'Akola', 'Jalgaon', 'Latur', 'Nanded', 'Satara',
  ],
  'Manipur': [
    'Imphal', 'Thoubal', 'Bishnupur', 'Churachandpur',
  ],
  'Meghalaya': [
    'Shillong', 'Tura', 'Jowai', 'Nongstoin',
  ],
  'Mizoram': [
    'Aizawl', 'Lunglei', 'Champhai', 'Serchhip',
  ],
  'Nagaland': [
    'Kohima', 'Dimapur', 'Mokokchung', 'Tuensang',
  ],
  'Odisha': [
    'Bhubaneswar', 'Cuttack', 'Rourkela', 'Berhampur', 'Sambalpur',
    'Puri', 'Balasore', 'Baripada', 'Bhadrak',
  ],
  'Punjab': [
    'Ludhiana', 'Amritsar', 'Jalandhar', 'Patiala', 'Bathinda',
    'Mohali', 'Hoshiarpur', 'Pathankot', 'Moga', 'Firozpur',
  ],
  'Rajasthan': [
    'Jaipur', 'Jodhpur', 'Udaipur', 'Kota', 'Ajmer', 'Bikaner',
    'Alwar', 'Bhilwara', 'Sikar', 'Bharatpur', 'Pali', 'Mount Abu',
  ],
  'Sikkim': [
    'Gangtok', 'Namchi', 'Gyalshing', 'Mangan',
  ],
  'Tamil Nadu': [
    'Chennai', 'Coimbatore', 'Madurai', 'Tiruchirappalli', 'Salem',
    'Tirunelveli', 'Erode', 'Vellore', 'Thoothukudi', 'Dindigul',
    'Thanjavur', 'Kanchipuram', 'Nagercoil',
  ],
  'Telangana': [
    'Hyderabad', 'Warangal', 'Nizamabad', 'Karimnagar', 'Khammam',
    'Ramagundam', 'Secunderabad', 'Mahbubnagar', 'Nalgonda',
  ],
  'Tripura': [
    'Agartala', 'Udaipur', 'Dharmanagar', 'Kailashahar',
  ],
  'Uttar Pradesh': [
    'Lucknow', 'Kanpur', 'Ghaziabad', 'Agra', 'Varanasi', 'Meerut',
    'Prayagraj', 'Noida', 'Bareilly', 'Aligarh', 'Moradabad',
    'Saharanpur', 'Gorakhpur', 'Jhansi', 'Mathura', 'Firozabad',
  ],
  'Uttarakhand': [
    'Dehradun', 'Haridwar', 'Rishikesh', 'Nainital', 'Roorkee',
    'Haldwani', 'Rudrapur', 'Kashipur',
  ],
  'West Bengal': [
    'Kolkata', 'Howrah', 'Durgapur', 'Asansol', 'Siliguri',
    'Bardhaman', 'Malda', 'Kharagpur', 'Darjeeling', 'Haldia',
  ],
  'Andaman and Nicobar Islands': ['Port Blair'],
  'Chandigarh': ['Chandigarh'],
  'Dadra and Nagar Haveli and Daman and Diu': ['Daman', 'Diu', 'Silvassa'],
  'Delhi NCR': [
    'New Delhi', 'North Delhi', 'South Delhi', 'East Delhi',
    'West Delhi', 'Dwarka', 'Rohini', 'Gurugram', 'Noida', 'Faridabad',
    'Ghaziabad',
  ],
  'Jammu and Kashmir': ['Srinagar', 'Jammu', 'Anantnag', 'Baramulla'],
  'Ladakh': ['Leh', 'Kargil'],
  'Lakshadweep': ['Kavaratti'],
  'Puducherry': ['Puducherry', 'Karaikal', 'Yanam', 'Mahe'],
};

List<String> get indiaStates => indiaStatesAndCities.keys.toList();

List<String> citiesForState(String? state) {
  if (state == null) return const [];
  return indiaStatesAndCities[state] ?? const [];
}