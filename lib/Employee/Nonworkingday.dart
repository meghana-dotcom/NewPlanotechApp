import 'package:flutter/material.dart';
import 'package:planotech/baseurl.dart';
import 'dart:convert';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:http/http.dart' as http;

class Nonworkingday extends StatefulWidget {
  final String empId;
  const Nonworkingday({super.key, required this.empId});
  @override
  State<Nonworkingday> createState() => _NonworkingdayState();
}

class _NonworkingdayState extends State<Nonworkingday> {
  List<dynamic> _allData = [];
  List<dynamic> _filteredData = [];
  bool _isLoading = true;
  final RefreshController _refreshController = RefreshController();
  String _selectedFilter = 'All'; // Default filter

  // Filter options
  final List<String> _filterOptions = [
    'All',
    'Approved',
    'Rejected',
    'Pending'
  ];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  String _toString(dynamic value) => value?.toString() ?? '';

  String _getCompOffReason(dynamic value) {
    final reason = _toString(value);
    return reason.isEmpty ? 'Not Provided' : reason;
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(baseurl +
            '/admin/fetchemployeeattendancebyemployeeid?empId=${widget.empId}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map && data.containsKey('userList')) {
          final compOffData = (data['userList'] as List)
              .where((item) => _toString(item['compOff']) == 'Yes')
              .toList();

          final groupedData = _groupByDate(compOffData);

          setState(() {
            _allData = groupedData;
            _applyFilter(); // Apply the current filter to the new data
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          backgroundColor: Colors.red[400],
        ),
      );
    } finally {
      _refreshController.refreshCompleted();
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _groupByDate(List<dynamic> data) {
    final Map<String, List<dynamic>> grouped = {};

    for (var item in data) {
      final date = _toString(item['date']);
      if (!grouped.containsKey(date)) {
        grouped[date] = [];
      }
      grouped[date]!.add(item);
    }

    return grouped.entries
        .map((entry) => {
              'date': entry.key,
              'day': entry.value.first['day'],
              'entries': entry.value,
              'status': entry.value.first['compOffStatus'],
            })
        .toList();
  }

  void _applyFilter() {
    if (_selectedFilter == 'All') {
      _filteredData = List.from(_allData);
    } else {
      _filteredData = _allData
          .where((dayData) =>
              _toString(dayData['status']).toLowerCase() ==
              _selectedFilter.toLowerCase())
          .toList();
    }
  }

  void _onFilterChanged(String? newValue) {
    if (newValue != null) {
      setState(() {
        _selectedFilter = newValue;
        _applyFilter();
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _buildEntryCard(Map<String, dynamic> entry) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.access_time, size: 18, color: Colors.blue[800]),
                const SizedBox(width: 8),
                Text(
                  "Time: ${_toString(entry['time'])}",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildInfoRow(Icons.work_outline, "Attendance Status",
                _toString(entry['attendanceStatus'])),
            _buildInfoRow(
                Icons.business, "Department", _toString(entry['department'])),
            _buildInfoRow(
                Icons.info_outline,
                "Your Reason",
                _toString(entry['reason']).isEmpty
                    ? 'Not Provided'
                    : _toString(entry['reason'])),
            _buildInfoRow(Icons.location_on_outlined, "Out of Location",
                _toString(entry['outOfLocation'])),
            _buildInfoRow(
                Icons.home_outlined, "Address", _toString(entry['address'])),
            _buildInfoRow(Icons.note_alt_outlined, "Status Reason",
                _getCompOffReason(entry['compOffReason']),
                isItalic: _toString(entry['compOffReason']).isEmpty),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      {bool isItalic = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                  fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
                ),
                children: [
                  TextSpan(
                    text: "$label: ",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Non Working Day',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Color.fromARGB(255, 30, 93, 209),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Filter Card
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: DropdownButtonFormField<String>(
                  value: _selectedFilter,
                  decoration: const InputDecoration(
                    labelText: 'Filter by Status',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  isExpanded: true,
                  icon: const Icon(Icons.filter_list_rounded),
                  items: _filterOptions.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value,
                        style: const TextStyle(fontSize: 14),
                      ),
                    );
                  }).toList(),
                  onChanged: _onFilterChanged,
                ),
              ),
            ),
          ),
          Expanded(
            child: SmartRefresher(
              controller: _refreshController,
              onRefresh: _fetchData,
              header: const WaterDropMaterialHeader(
                backgroundColor: Color(0xFFB31A1A),
              ),
              child: _isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFFB31A1A),
                            ),
                            strokeWidth: 3,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Loading your non working off days...',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : _filteredData.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 64,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No comp off days found',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[600],
                                ),
                              ),
                              if (_selectedFilter != 'All')
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    'for status: $_selectedFilter',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 16),
                              OutlinedButton(
                                onPressed: _fetchData,
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  side: BorderSide(
                                    color: Colors.grey[400]!,
                                  ),
                                ),
                                child: const Text('Refresh'),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          itemCount: _filteredData.length,
                          itemBuilder: (context, index) {
                            final dayData = _filteredData[index];
                            final status = _toString(dayData['status']);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Card(
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: _getStatusColor(status)
                                        .withOpacity(0.3),
                                    width: 1.5,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _toString(dayData['date']),
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              Text(
                                                _toString(dayData['day']),
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(status)
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                color: _getStatusColor(status),
                                                width: 1,
                                              ),
                                            ),
                                            child: Text(
                                              status,
                                              style: TextStyle(
                                                color: _getStatusColor(status),
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      ...dayData['entries']
                                          .map<Widget>(
                                              (e) => _buildEntryCard(e))
                                          .toList(),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }
}
