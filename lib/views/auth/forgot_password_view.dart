import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:voiceup/controllers/forgot_password_controller.dart';
import 'package:voiceup/theme/app_theme.dart';

class ForgotPasswordView extends StatelessWidget {
  const ForgotPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    // Injection du contrôleur via GetX
    final controller = Get.put(ForgotPasswordController());

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Row(
                  children: [
                    IconButton(
                      onPressed: controller.goBackToLogin,
                      icon: const Icon(Icons.arrow_back),
                    ),
                    SizedBox(width: 8),
                    Text(
                      "Forgot Password",
                      style: Theme
                          .of(context)
                          .textTheme
                          .headlineLarge,


                    ),
                  ],
                ),
                SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 56),
                  child: Text(
                    "Enter your email to receive a password reset link",
                    style: Theme
                        .of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ),
                SizedBox(height: 60),
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Icon(
                      Icons.lock_reset_rounded,
                      size: 50,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                SizedBox(height: 40),
                Obx(() {
                  if (controller.emailSent) {
                    // Si l'email est envoyé, on affiche le contenu de succès
                     return _buildEmailSentContent(controller);

                  } else {
                    // Sinon, on affiche le formulaire de saisie
                    return _buildEmailForm(controller);
                  }
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailForm(ForgotPasswordController controller) {
    return Column(
      children: [
        TextFormField(
          controller: controller.emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Email',
            prefixIcon: const Icon(Icons.email_outlined),
            hintText: 'Enter your email',
          ),
          validator: controller.validateEmail,
        ),
        const SizedBox(height: 32),
        Obx(
              () => SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: controller.isLoading
                  ? null
                  : controller.sentPasswordResetEmail,
              icon: controller.isLoading
                  ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : Icon(Icons.send),
              label: Text(
                controller.isLoading ? 'Sending...' : 'Send Reset Link',
              ),
            ),
          ),
        ),
        SizedBox(height: 32),
        Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
        Text(
        "Remember your password?",
        style: Theme.of(Get.context!).textTheme.bodyMedium,
        ),
        SizedBox(width: 8),
        GestureDetector(
        onTap: controller.goBackToLogin,
        child: Text(
        ' Sign In',
        style: Theme.of(Get.context!).textTheme.bodyMedium?.copyWith(
        color: Theme.of(Get.context!).primaryColor,
        fontWeight: FontWeight.bold,
        ),
        ),
        ),

      ],
    ),
  ],
    );
  }
  Widget _buildEmailSentContent(ForgotPasswordController controller) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.successColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.successColor.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(
                Icons.mark_email_read_rounded,
                size: 60,
                color: AppTheme.successColor,
              ),
              SizedBox(height: 16),
              Text(
                "Email Sent!",
                style: Theme.of(Get.context!).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.successColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "we've sent a password reset link to:",
                style: Theme.of(Get.context!).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 4),
              Text(
                controller.emailController.text,
                style: Theme.of(Get.context!).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ), // Text
              SizedBox(height: 12),
              Text(
                'Check your email and follow the instructions to reset your password',
                style: Theme.of(Get.context!).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
            SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: controller.resendEmail,
                icon: Icon(Icons.refresh),
                label: Text("Resend Email"),
              ),
            ),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: controller.goBackToLogin,
                icon: Icon(Icons.arrow_back),
                label: Text("Back To sign In"),
              ),
            ),
        SizedBox(height: 24),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.secondaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ), // BoxDecoration
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 20,
                color: AppTheme.secondaryColor,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Didn't receive the email? Check tour spam folder or try again",
                  style: Theme.of(Get.context!).textTheme.bodySmall?.copyWith(
                    color: AppTheme.secondaryColor,
                  ),
                ), // Text
              ),
            ],
          ),
        ),
      ],
    );
  }
}

