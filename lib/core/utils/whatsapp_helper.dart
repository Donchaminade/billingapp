import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class WhatsappHelper {
  static Future<void> sendReceipt({
    required File pdfFile,
    required String phoneNumber,
    required String shopName,
  }) async {
    // Nettoyage du numéro de téléphone (garder seulement les chiffres)
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    
    // Message de remerciement
    final message = "Merci de votre achat chez $shopName ! Voici votre reçu en pièce jointe. À bientôt !";
    
    // Sur mobile, on utilise share_plus pour envoyer le fichier. 
    // WhatsApp permet de recevoir des fichiers via le partage système.
    // Pour un message direct avec fichier, c'est plus complexe via URL, 
    // donc l'approche standard est de partager le fichier et de laisser l'utilisateur choisir WhatsApp.
    
    await Share.shareXFiles(
      [XFile(pdfFile.path)],
      text: message,
      subject: 'Reçu de votre achat - $shopName',
    );
  }
  
  // Alternative si l'utilisateur veut juste ouvrir WhatsApp avec un message (sans fichier)
  static Future<void> openWhatsappWithMessage(String phoneNumber, String message) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    final url = "https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}";
    
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }
}
