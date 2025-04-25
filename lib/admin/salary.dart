import 'package:flutter/material.dart';

class AdminSalaryEntryPage extends StatefulWidget {
  const AdminSalaryEntryPage({Key? key}) : super(key: key);

  @override
  _AdminSalaryEntryPageState createState() => _AdminSalaryEntryPageState();
}

class _AdminSalaryEntryPageState extends State<AdminSalaryEntryPage> {
  final _formKey = GlobalKey<FormState>();

  // Text controllers for each field
  final _employeeNameController = TextEditingController();
  final _employeeCodeController = TextEditingController();
  final _designationController = TextEditingController();
  final _departmentController = TextEditingController();
  final _dojController = TextEditingController();

  final _bankAccountController = TextEditingController();
  final _ifscController = TextEditingController();
  final _genderController = TextEditingController();

  final _uanController = TextEditingController();
  final _pfController = TextEditingController();
  final _esiController = TextEditingController();

  final _payMonthYearController = TextEditingController();
  final _workingDaysController = TextEditingController();
  final _leaveDaysController = TextEditingController();

  final _basicSalaryController = TextEditingController();
  final _hraController = TextEditingController();
  final _otherAllowanceController = TextEditingController();
  final _reimbursementsController = TextEditingController();
  final _earnedGrossController = TextEditingController();
  final _totalEarningsController = TextEditingController();

  final _epfDeductionController = TextEditingController();
  final _esiDeductionController = TextEditingController();
  final _ptController = TextEditingController();
  final _loanController = TextEditingController();
  final _otherDeductionController = TextEditingController();
  final _totalDeductionController = TextEditingController();

  final _netPayController = TextEditingController();

  final _grossEarningsController = TextEditingController();
  final _epfContriController = TextEditingController();
  final _esiContriController = TextEditingController();
  final _healthInsuranceController = TextEditingController();
  final _ctcController = TextEditingController();

  @override
  void dispose() {
    _employeeNameController.dispose();
    // Dispose all others like above...
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // You can now construct the SalarySlip object or send to backend
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Salary Slip Saved!")),
      );
    }
  }

  Widget _buildTextField(String label, TextEditingController controller, {TextInputType type = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) => value == null || value.isEmpty ? 'Required' : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter Salary Slip'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [

              const Text('Personal Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              _buildTextField("Employee Name", _employeeNameController),
              _buildTextField("Employee Code", _employeeCodeController),
              _buildTextField("Designation", _designationController),
              _buildTextField("Department", _departmentController),
              _buildTextField("Date of Joining", _dojController),
              _buildTextField("Gender", _genderController),

              const SizedBox(height: 10),
              const Text('Bank & ID Info', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              _buildTextField("Bank A/C No.", _bankAccountController),
              _buildTextField("IFSC Code", _ifscController),
              _buildTextField("UAN No.", _uanController),
              _buildTextField("PF No.", _pfController),
              _buildTextField("ESI No.", _esiController),

              const SizedBox(height: 10),
              const Text('Salary Month & Days', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              _buildTextField("Pay Month & Year", _payMonthYearController),
              _buildTextField("Working Days", _workingDaysController, type: TextInputType.number),
              _buildTextField("Leave Days", _leaveDaysController, type: TextInputType.number),

              const SizedBox(height: 10),
              const Text('Earnings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              _buildTextField("Basic Salary", _basicSalaryController, type: TextInputType.number),
              _buildTextField("HRA", _hraController, type: TextInputType.number),
              _buildTextField("Other Allowance", _otherAllowanceController, type: TextInputType.number),
              _buildTextField("Reimbursements", _reimbursementsController, type: TextInputType.number),
              _buildTextField("Earned Gross Salary", _earnedGrossController, type: TextInputType.number),
              _buildTextField("Total Earnings", _totalEarningsController, type: TextInputType.number),

              const SizedBox(height: 10),
              const Text('Deductions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              _buildTextField("EPF", _epfDeductionController, type: TextInputType.number),
              _buildTextField("ESI", _esiDeductionController, type: TextInputType.number),
              _buildTextField("PT", _ptController, type: TextInputType.number),
              _buildTextField("Loans", _loanController, type: TextInputType.number),
              _buildTextField("Other Deductions", _otherDeductionController, type: TextInputType.number),
              _buildTextField("Total Deductions", _totalDeductionController, type: TextInputType.number),

              const SizedBox(height: 10),
              _buildTextField("Net Pay", _netPayController, type: TextInputType.number),

              const SizedBox(height: 10),
              const Text('Employer Contributions (CTC)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              _buildTextField("Gross Earnings", _grossEarningsController, type: TextInputType.number),
              _buildTextField("EPF Contribution", _epfContriController, type: TextInputType.number),
              _buildTextField("ESI Contribution", _esiContriController, type: TextInputType.number),
              _buildTextField("Health Insurance", _healthInsuranceController, type: TextInputType.number),
              _buildTextField("CTC", _ctcController, type: TextInputType.number),

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                child: const Text('Save Salary Slip'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
