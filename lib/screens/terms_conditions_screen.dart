import 'package:flutter/material.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Terms and Conditions',
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
              'Welcome to SkipQ! These Terms and Conditions ("Terms") govern your use of our queue management service operated by Solid Apps, located in Kochi, Kerala, India. By accessing or using SkipQ, you agree to be bound by these Terms.',
            ),

            _buildSection(
              '1. Acceptance of Terms',
              'By using SkipQ, you confirm that:\n\n'
              '• You accept these Terms and Conditions\n'
              '• You agree to comply with all applicable laws\n'
              '• You are using the service for lawful purposes only\n\n'
              'If you do not agree with these Terms, please do not use our service.',
            ),

            _buildSection(
              '2. Service Description',
              'SkipQ provides:\n\n'
              '• Digital queue management system\n'
              '• Real-time queue position tracking\n'
              '• Wait time estimation\n'
              '• Queue administration tools\n'
              '• QR code generation for easy queue joining\n\n'
              'The service is provided "as is" without warranties of any kind.',
            ),

            _buildSection(
              '3. User Responsibilities',
              'As a queue member, you agree to:\n\n'
              '• Provide accurate information when joining a queue\n'
              '• Use your real name (or a name that identifies you)\n'
              '• Respect your position in the queue\n'
              '• Not abuse or manipulate the queue system\n'
              '• Not create fake or spam queue entries',
            ),

            _buildSection(
              '4. Queue Administrator Responsibilities',
              'As a queue administrator, you agree to:\n\n'
              '• Keep your admin PIN secure and confidential\n'
              '• Use the service responsibly and legally\n'
              '• Respect the privacy of queue members\n'
              '• Not discriminate against any queue members\n'
              '• Delete queues and member data when no longer needed\n'
              '• Comply with applicable data protection laws',
            ),

            _buildSection(
              '5. Prohibited Activities',
              'You must not:\n\n'
              '• Use the service for illegal purposes\n'
              '• Attempt to hack or compromise the system\n'
              '• Create automated bots to manipulate queues\n'
              '• Harass or abuse other users\n'
              '• Share admin PINs with unauthorized persons\n'
              '• Violate intellectual property rights\n'
              '• Impersonate others or create fake identities',
            ),

            _buildSection(
              '6. Data and Privacy',
              'By using SkipQ:\n\n'
              '• You acknowledge that your name and queue position are visible to other queue members\n'
              '• You consent to the collection and use of data as described in our Privacy Policy\n'
              '• You understand that queue admins can see all member information\n'
              '• You agree that data is stored on Google Firebase servers\n\n'
              'Please read our Privacy Policy for detailed information.',
            ),

            _buildSection(
              '7. Intellectual Property',
              'SkipQ and all related content are owned by Solid Apps:\n\n'
              '• The SkipQ name, logo, and design are our property\n'
              '• You may not copy, modify, or distribute our software\n'
              '• You may not reverse engineer our application\n'
              '• All rights not expressly granted are reserved',
            ),

            _buildSection(
              '8. Service Availability',
              'We strive to provide reliable service, but:\n\n'
              '• We do not guarantee 100% uptime\n'
              '• Service may be interrupted for maintenance\n'
              '• We may modify or discontinue features without notice\n'
              '• We are not liable for service interruptions\n'
              '• Queue data may be lost due to technical issues',
            ),

            _buildSection(
              '9. Limitation of Liability',
              'To the fullest extent permitted by law:\n\n'
              '• Solid Apps is not liable for any indirect, incidental, or consequential damages\n'
              '• We are not responsible for lost business or revenue\n'
              '• We are not liable for data loss or corruption\n'
              '• Our total liability is limited to the amount you paid (if any)\n'
              '• We are not liable for third-party service failures',
            ),

            _buildSection(
              '10. Disclaimer of Warranties',
              'SkipQ is provided "AS IS" and "AS AVAILABLE" without warranties:\n\n'
              '• We do not guarantee error-free operation\n'
              '• We do not warrant that the service will meet your requirements\n'
              '• We do not guarantee the accuracy of wait time estimates\n'
              '• We disclaim all implied warranties of merchantability',
            ),

            _buildSection(
              '11. Indemnification',
              'You agree to indemnify and hold Solid Apps harmless from:\n\n'
              '• Claims arising from your use of the service\n'
              '• Your violation of these Terms\n'
              '• Your violation of any third-party rights\n'
              '• Any damage caused by your actions',
            ),

            _buildSection(
              '12. Account Termination',
              'We reserve the right to:\n\n'
              '• Suspend or terminate your access at any time\n'
              '• Remove queues that violate these Terms\n'
              '• Delete abusive or inappropriate content\n'
              '• Ban users who engage in prohibited activities\n\n'
              'You may stop using the service at any time.',
            ),

            _buildSection(
              '13. Changes to Terms',
              'We may modify these Terms at any time:\n\n'
              '• Changes will be posted on this page\n'
              '• The "Last updated" date will be revised\n'
              '• Continued use after changes means you accept the new Terms\n'
              '• We will notify users of significant changes when possible',
            ),

            _buildSection(
              '14. Governing Law',
              'These Terms are governed by:\n\n'
              '• The laws of India\n'
              '• Kerala state jurisdiction\n'
              '• Disputes will be resolved in courts of Kochi, Kerala\n\n'
              'However, we encourage resolving disputes amicably through direct communication.',
            ),

            _buildSection(
              '15. Contact Information',
              'For questions about these Terms, contact us:\n\n'
              'Solid Apps\n'
              'Kochi, Kerala, India\n'
              'Email: solidapps.development@gmail.com\n\n'
              'We will respond to inquiries within 7 business days.',
            ),

            _buildSection(
              '16. Severability',
              'If any provision of these Terms is found to be invalid or unenforceable:\n\n'
              '• That provision will be limited or eliminated to the minimum extent necessary\n'
              '• The remaining Terms will remain in full force and effect',
            ),

            _buildSection(
              '17. Entire Agreement',
              'These Terms, together with our Privacy Policy, constitute the entire agreement between you and Solid Apps regarding the use of SkipQ.',
            ),

            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_outlined, color: Colors.orange.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Important: Solid Apps is not a registered company. This is an independent software service.',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.green.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'By using SkipQ, you acknowledge that you have read, understood, and agree to be bound by these Terms and Conditions.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.green.shade900,
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
