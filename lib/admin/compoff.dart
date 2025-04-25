import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:planotech/baseurl.dart';

class Compoff extends StatefulWidget {
  const Compoff({super.key});

  @override
  State<Compoff> createState() => _CompoffState();
}

class _CompoffState extends State<Compoff> {
  List<dynamic> _compoffList = [];
  List<dynamic> _filteredCompoffList = [];
  
  bool _isLoading = false;
  bool _hasError = false;
  String _message = "";
  TextEditingController _searchController = TextEditingController();

  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  // Filter variables
  String? _selectedDepartment;
  String? _selectedStatus;
  bool _showFilters = false;

  final List<String> _months = [
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December"
  ];

  final List<String> _statusOptions = ['Pending', 'Approved', 'Rejected'];
  
  final List<String> _departmentOptions = [
    'IT',
    'Administration',
    'HR',
    'Sales and Marketing',
    'Design',
    'Finance and Accounts',
    'Production',
    'Operations-Support',
    'Interns',
    'TestAccount'
  ];

  Future<void> _fetchCompoffData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    String url =
        baseurl+'/admin/fetchallcompoffbymonth?month=$_selectedMonth&year=$_selectedYear';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        print('*fetch all compoff $responseData');

        setState(() {
          _message = responseData["message"] ?? "";
          _compoffList = responseData["userList"] ?? [];
          _applyAllFilters();
        });
      } else {
        _hasError = true;
      }
    } catch (e) {
      _hasError = true;
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _applyAllFilters() {
    setState(() {
      _filteredCompoffList = _compoffList.where((employee) {
        // Name filter
        final nameMatch = _searchController.text.isEmpty || 
            (employee['name_of_the_Employee'] ?? '').toLowerCase()
                .contains(_searchController.text.toLowerCase());
        
        // Department filter
        final departmentMatch = _selectedDepartment == null || 
            (employee['department'] ?? '') == _selectedDepartment;
        
        // Status filter
        bool statusMatch = true;
        if (_selectedStatus != null) {
          final attendanceDetails = employee['dayAndDate'][0]['attendance_Details'][0];
          statusMatch = (attendanceDetails['compOffStatus'] ?? 'Pending') == _selectedStatus;
        }
        
        return nameMatch && departmentMatch && statusMatch;
      }).toList();
    });
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _selectedDepartment = null;
      _selectedStatus = null;
      _applyAllFilters();
    });
  }

  void _showCompOffEditDialog(BuildContext context, dynamic employee) {
    var attendanceDetails = employee['dayAndDate'][0]['attendance_Details'][0];
    String currentStatus = attendanceDetails['compOffStatus'] ?? 'Pending';
    String currentReason = attendanceDetails['compOffReason'] ?? '';
    String attendanceId = attendanceDetails['id'].toString(); 
    print('Attendance ID: $attendanceId');
    TextEditingController _reasonController = TextEditingController(text: currentReason);  
    
    showDialog(
      context: context,
      builder: (context) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        "Edit CompOff Details",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "STATUS",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ..._statusOptions.map((status) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: currentStatus == status 
                                        ? _getStatusColor(status).withOpacity(0.1)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: RadioListTile<String>(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(
                                      status,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: _getStatusColor(status),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    value: status,
                                    groupValue: currentStatus,
                                    activeColor: _getStatusColor(status),
                                    onChanged: (value) {
                                      setState(() {
                                        currentStatus = value!;
                                      });
                                    },
                                  ),
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "REASON",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _reasonController,
                              maxLength: 200,
                              maxLines: 5,
                              minLines: 3,
                              maxLengthEnforcement: MaxLengthEnforcement.enforced,
                              style: const TextStyle(fontSize: 14),
                              decoration: InputDecoration(
                                hintText: "Enter your reason here...",
                                hintStyle: TextStyle(color: Colors.grey[400]),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey[300]!),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey[300]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Colors.blue, width: 1.5),
                                ),
                                contentPadding: const EdgeInsets.all(12),
                                counterText: "${_reasonController.text.length}/200 characters",
                                counterStyle: TextStyle(
                                  color: _reasonController.text.length >= 200 
                                      ? Colors.red 
                                      : Colors.grey,
                                ),
                              ),
                              onChanged: (value) {
                                if (value.length > 200) {
                                  _reasonController.text = value.substring(0, 200);
                                  _reasonController.selection = TextSelection.collapsed(offset: 200);
                                }
                                setState(() {});
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                side: BorderSide(color: Colors.grey[300]!),
                              ),
                              child: const Text(
                                "Cancel",
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isSaving ? null : () async {
                                setState(() => isSaving = true);
                                final newReason = _reasonController.text;
                                final updatedId = await _updateCompOffStatus(
                                  id: attendanceId, 
                                  compOffStatus: currentStatus,
                                  compOffReason: newReason,
                                );
                                setState(() => isSaving = false);
                                
                                print('Updated with ID: $updatedId');
                                if (updatedId != null && context.mounted) {
                                  Navigator.pop(context);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1790C8),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 0,
                              ),
                              child: isSaving
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text(
                                    "Save Changes",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  )
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Approved':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      case 'Pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Future<String?> _updateCompOffStatus({
    required String id,
    required String compOffStatus,
    required String compOffReason,
  }) async {
    if (!mounted) return null;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final url = Uri.parse(
        baseurl+'/admin/compoffapprovel?'
        'id=$id&'
        'compOffStatus=$compOffStatus&'
        'compOffReason=${Uri.encodeComponent(compOffReason)}'
      );

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (!mounted) return null;
      
      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        if (responseData['status'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Successfully updated CompOff!'),
              backgroundColor: Colors.green,
            ),
          );
          await _fetchCompoffData();
          return id;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(responseData['statusMessage'] ?? 'Update failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchCompoffData();
    _searchController.addListener(() {
      _applyAllFilters();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _selectMonthYear() {
    int tempMonth = _selectedMonth;
    int tempYear = _selectedYear;
    DateTime now = DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Select Month & Year"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<int>(
                    value: tempMonth,
                    isExpanded: true,
                    items: List.generate(
                      12,
                      (index) => DropdownMenuItem(
                        value: index + 1,
                        child: Text(
                          _months[index],
                          style: TextStyle(
                            color: (tempYear > now.year || (tempYear == now.year && index + 1 > now.month))
                                ? Colors.grey
                                : Colors.black,
                          ),
                        ),
                        enabled: !(tempYear > now.year || (tempYear == now.year && index + 1 > now.month)),
                      ),
                    ),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() {
                          tempMonth = value;
                        });
                      }
                    },
                  ),
                  DropdownButton<int>(
                    value: tempYear,
                    isExpanded: true,
                    items: List.generate(
                      500,
                      (index) => DropdownMenuItem(
                        value: 2000 + index,
                        child: Text(
                          "Year: ${2000 + index}",
                          style: TextStyle(
                            color: (2000 + index > now.year) ? Colors.grey : Colors.black,
                          ),
                        ),
                        enabled: !(2000 + index > now.year),
                      ),
                    ),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() {
                          tempYear = value;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedMonth = tempMonth;
                      _selectedYear = tempYear;
                    });
                    _fetchCompoffData();
                    Navigator.pop(context);
                  },
                  child: const Text("Apply"),
                ),
              ],
            );
          },
        );
      },
    );
  }

Widget _buildFilterChip(String label, bool selected, VoidCallback onTap) {
  return FilterChip(
    label: Text(label),
    selected: selected,
    onSelected: (bool value) => onTap(),
    backgroundColor: Colors.white,
    selectedColor:  Colors.green,
    labelStyle: TextStyle(
      color: selected ? Colors.white : Colors.black,
    ),
    side: BorderSide(
      color: selected ? const Color(0xFF1790C8) : Colors.grey[300]!,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Non Working Days \n ${_months[_selectedMonth - 1]} $_selectedYear',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        toolbarHeight: 100,
        backgroundColor: const Color.fromARGB(255, 179, 26, 26),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            style: ButtonStyle(
              iconColor: WidgetStatePropertyAll(Color.fromARGB(237, 250, 245, 241)),
              iconSize: WidgetStatePropertyAll(35)),
            onPressed: _selectMonthYear,
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Search by name",
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton.icon(
                      icon:  Icon(Icons.filter_alt_sharp, size: 20,color: Colors.amber[300],),
                      label: Text(_showFilters ? "Hide Filters" : "Show Filters"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:  const Color.fromARGB(255, 185, 35, 35),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onPressed: () {
                        setState(() {
                          _showFilters = !_showFilters;
                        });
                      },
                    ),
                    if (_selectedDepartment != null || _selectedStatus != null)
                      TextButton(
                        onPressed: _resetFilters,
                        child: const Text("Clear Filters"),
                      ),
                  ],
                ),
                if (_showFilters)
                  SizedBox(
                    height: 250,
                    child: Card(
                      margin: const EdgeInsets.only(top: 8),
                      elevation: 2,
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Department:",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _departmentOptions.map((dept) {
                                  return _buildFilterChip(
                                    dept,
                                    _selectedDepartment == dept,
                                    () {
                                      setState(() {
                                        _selectedDepartment = _selectedDepartment == dept ? null : dept;
                                        _applyAllFilters();
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                "CompOff Status:",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _statusOptions.map((status) {
                                  return _buildFilterChip(
                                    status,
                                    _selectedStatus == status,
                                    () {
                                      setState(() {
                                        _selectedStatus = _selectedStatus == status ? null : status;
                                        _applyAllFilters();
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _hasError
                    ? const Center(
                        child: Text(
                          'Failed to load data!',
                          style: TextStyle(color: Colors.red, fontSize: 16),
                        ),
                      )
                    : _filteredCompoffList.isEmpty
                        ? Center(
                            child: Text(
                              'No CompOff records found',
                              style: TextStyle(fontSize: 16, color: Colors.black54),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(10),
                            itemCount: _filteredCompoffList.length,
                            itemBuilder: (context, index) {
                              var employee = _filteredCompoffList[index];
                              
                              Set<String> allReasons = {};
                              for (var day in employee['dayAndDate']) {
                                for (var details in day['attendance_Details']) {
                                  if (details['reason'] != null && details['reason'].isNotEmpty) {
                                    allReasons.add(details['reason']);
                                  }
                                }
                              }
                              
                              bool showCombinedReason = allReasons.length == 1;

                              String currentCompOffStatus = employee['dayAndDate'][0]['attendance_Details'][0]['compOffStatus'] ?? 'Pending';
                              String currentcompOffReason = employee['dayAndDate'][0]['attendance_Details'][0]['compOffReason'] ?? '';

                              return Card(
                                elevation: 6,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                                color: Colors.white,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                  child: ExpansionTile(
                                    tilePadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    backgroundColor: Colors.white,
                                    collapsedBackgroundColor: Colors.white,
                                    title: Row(
                                      children: [
                                        const Icon(Icons.person, color: Color.fromARGB(255, 177, 27, 27), size: 30),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            employee['name_of_the_Employee'] ?? 'Unknown',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        "Department: ${employee['department']}",
                                        style: const TextStyle(fontSize: 16, color: Colors.black),
                                      ),
                                    ),
                                    children: [
                                      ...employee['dayAndDate'].map<Widget>((day) {
                                        return Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: const Color.fromARGB(255, 220, 229, 231),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  const Icon(Icons.calendar_today, color: Colors.black54, size: 22),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    "Date: ${day['date']} (${day['day']})",
                                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              ...day['attendance_Details'].map<Widget>((details) {
                                                return Padding(
                                                  padding: const EdgeInsets.only(top: 4),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          const Icon(Icons.access_time, color: Colors.black54, size: 22),
                                                          const SizedBox(width: 8),
                                                          Text("Time: ${details['time']}", style: const TextStyle(fontSize: 18)),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Row(
                                                        children: [
                                                          const Icon(Icons.location_on, color: Colors.black54, size: 22),
                                                          const SizedBox(width: 8),
                                                          Expanded(
                                                            child: Text("Address: ${details['address']}", style: const TextStyle(fontSize: 18)),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Row(
                                                        children: [
                                                          const Icon(Icons.warning_amber_rounded, color: Colors.black54, size: 22),
                                                          const SizedBox(width: 8),
                                                          Text(
                                                            "Out of Location: ${details['outOfLocation']}",
                                                            style: const TextStyle(fontSize: 18),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 4),
                                                      if (!showCombinedReason && details['reason'] != null && details['reason'].isNotEmpty)
                                                        Row(
                                                          children: [
                                                            const Icon(Icons.chat_bubble_outline, color: Colors.black, size: 22),
                                                            const SizedBox(width: 8),
                                                            Expanded(
                                                              child: Text("Reason: ${details['reason']}", style: const TextStyle(fontSize: 18)),
                                                            ),
                                                          ],
                                                        ),
                                                      const SizedBox(height: 4),
                                                      Row(
                                                        children: [
                                                          const Icon(Icons.stacked_bar_chart_rounded, color: Colors.black54, size: 22),
                                                          const SizedBox(width: 8),
                                                          Text(
                                                            "Status: ${details['attendance_status']}",
                                                            style: const TextStyle(fontSize: 18),
                                                          ),
                                                        ],
                                                      ),
                                                      const Divider(thickness: 1, color: Colors.black26),
                                                    ],
                                                  ),
                                                );
                                              }).toList(),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                      if (showCombinedReason && allReasons.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 8),
                                          child: Row(
                                            children: [
                                              SizedBox(width:50, child: const Icon(Icons.note_add_outlined, color: Colors.black, size: 22)),
                                              Expanded(
                                                child: Text("Reason : ${allReasons.first}", style: const TextStyle(fontSize: 18)),
                                              ),
                                            ],
                                          ),
                                        ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.edit_calendar_sharp, color: Colors.black, size: 22),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                "CompOff Status: ${employee['dayAndDate'][0]['attendance_Details'][0]['compOffStatus'] ?? 'Pending'}",
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  color: currentCompOffStatus == 'Approved' 
                                                      ? Colors.green 
                                                      : currentCompOffStatus == 'Rejected'
                                                          ? Colors.red
                                                          : Colors.orange,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.note, color: Colors.black, size: 22),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                currentcompOffReason.isEmpty
                                                    ? "CompOff Reason: Not provided"
                                                    : "CompOff Reason: ${currentcompOffReason.length > 200 
                                                        ? currentcompOffReason.substring(0, 200) + '...' 
                                                        : currentcompOffReason}",
                                                style: const TextStyle(fontSize: 16),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        child: Center(
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color.fromARGB(255, 207, 168, 158),
                                              padding: const EdgeInsets.symmetric(vertical: 14,horizontal: 14),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              elevation: 0,
                                            ),
                                            onPressed: () => _showCompOffEditDialog(context, employee),
                                            child: const Text("Edit CompOff Details  >>",style: TextStyle(color: Color.fromARGB(255, 87, 67, 79),fontWeight:FontWeight.bold,fontSize: 18),
                                          ),
                                        ),
                                      ),
                                      )
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}