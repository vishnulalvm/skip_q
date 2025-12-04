import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Privacy Policy for SkipQ',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Last updated: ${DateTime.now().toString().split(' ')[0]}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),

            _buildSection(
              'Introduction',
              'Welcome to SkipQ, a queue management system operated by Solid Apps, located in Kochi, Kerala, India. We respect your privacy and are committed to protecting your personal data. This privacy policy explains how we collect, use, and protect your information when you use our service.',
            ),

            _buildSection(
              '1. Information We Collect',
              'We collect the following information:\n\n'
              '• Customer Name: When you join a queue\n'
              '• Queue Position: Automatically assigned token number\n'
              '• Quantity Requested: Number of items you need\n'
              '• Timestamps: When you join and are served\n'
              '• Queue Information: Queue name, status, and statistics\n'
              '• Admin PIN: For queue management access (encrypted)',
            ),

            _buildSection(
              '2. Information We DO NOT Collect',
              'We do not collect:\n\n'
              '• Email addresses\n'
              '• Phone numbers\n'
              '• Physical addresses\n'
              '• Payment information\n'
              '• Location data\n'
              '• Device identifiers',
            ),

            _buildSection(
              '3. How We Use Your Information',
              'We use your information to:\n\n'
              '• Manage queue positions and wait times\n'
              '• Display your place in line\n'
              '• Notify you when it\'s your turn\n'
              '• Calculate estimated wait times\n'
              '• Provide queue statistics to admins\n'
              '• Improve our service quality',
            ),

            _buildSection(
              '4. Data Storage',
              'Your data is stored securely using Google Firebase Cloud Firestore:\n\n'
              '• Data is stored on Google\'s secure servers\n'
              '• All data transmission is encrypted (HTTPS)\n'
              '• Data is retained until the queue admin deletes it\n'
              '• Queue admins can delete member data at any time',
            ),

            _buildSection(
              '5. Data Sharing and Visibility',
              'Your name and queue position are visible to:\n\n'
              '• Other people in the same queue\n'
              '• The queue administrator\n'
              '• Anyone with the queue link\n\n'
              'We do NOT share your data with third parties for marketing purposes.',
            ),

            _buildSection(
              '6. Third-Party Services',
              'We use the following third-party services:\n\n'
              '• Google Firebase: For data storage and real-time updates\n'
              '• Google Analytics: For usage statistics (anonymized)\n\n'
              'These services have their own privacy policies governing their use of information.',
            ),

            _buildSection(
              '7. Your Rights',
              'You have the right to:\n\n'
              '• Request deletion of your queue member data\n'
              '• Ask the queue admin to remove you from a queue\n'
              '• Decline to provide information (you cannot join queue without providing a name)',
            ),

            _buildSection(
              '8. Data Retention',
              'Queue member data is retained:\n\n'
              '• Until the queue is deleted by the admin\n'
              '• Until the admin manually deletes individual members\n'
              '• There is no automatic deletion period\n\n'
              'Admins have full control over data retention for their queues.',
            ),

            _buildSection(
              '9. Security',
              'We implement security measures including:\n\n'
              '• HTTPS encryption for all data transmission\n'
              '• Firebase security rules to protect data access\n'
              '• PIN-based access control for queue management\n\n'
              'However, no method of transmission over the Internet is 100% secure.',
            ),

            _buildSection(
              '10. Children\'s Privacy',
              'Our service does not specifically target children under 13. We do not knowingly collect personal information from children. If you are a parent and believe your child has provided us with information, please contact us.',
            ),

            _buildSection(
              '11. Changes to This Privacy Policy',
              'We may update this privacy policy from time to time. We will notify you of any changes by posting the new policy on this page and updating the "Last updated" date.',
            ),

            _buildSection(
              '12. Contact Us',
              'If you have questions about this Privacy Policy, please contact us:\n\n'
              'Solid Apps\n'
              'Kochi, Kerala, India\n'
              'Email: solidapps.development@gmail.com',
            ),

            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'By using SkipQ, you acknowledge that you have read and understood this Privacy Policy.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 15,
              height: 1.6,
              color: Color(0xFF4B5563),
            ),
          ),
        ],
      ),
    );
  }
}
