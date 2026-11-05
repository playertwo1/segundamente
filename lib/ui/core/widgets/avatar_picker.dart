import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:memex/ui/core/themes/app_colors.dart';
import 'package:memex/ui/core/widgets/character_avatar.dart';
import 'package:memex/utils/user_storage.dart';

const _avatarOptions = [
  'asset://characters/advogado_diabo.png',
  'asset://characters/amigo_bar.png',
  'asset://characters/calmo_crise.png',
  'asset://characters/cobrador_prazo.png',
  'asset://characters/curador.png',
  'asset://characters/diario_bordo.png',
  'asset://characters/financas_burocracia.png',
  'asset://characters/gerente_escopo.png',
  'asset://characters/guardiao_energia.png',
  'asset://characters/memoria_projeto.png',
  'asset://characters/parceiro_foco.png',
  'asset://characters/provocador_criativo.png',
  'asset://characters/revisor_chato.png',
  'asset://characters/socio_tecnico.png',
  'asset://characters/tradutor.png',
];

Future<String?> pickAvatarImageFromGallery() async {
  final picker = ImagePicker();
  final picked = await picker.pickImage(
    source: ImageSource.gallery,
    maxWidth: 512,
    maxHeight: 512,
    imageQuality: 85,
  );
  return picked?.path;
}

/// Shows the bundled portraits and a gallery option.
/// Returns the selected bundled asset URI or saved local image path, or null.
Future<String?> showAvatarPicker(
  BuildContext context,
  String currentAvatar, {
  Future<String?> Function()? onPickGallery,
}) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: AppColors.cardBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => _AvatarPickerSheet(
      currentAvatar: currentAvatar,
      onPickGallery: onPickGallery,
    ),
  );
}

class _AvatarPickerSheet extends StatelessWidget {
  const _AvatarPickerSheet({
    required this.currentAvatar,
    this.onPickGallery,
  });

  final String currentAvatar;
  final Future<String?> Function()? onPickGallery;

  Future<void> _pickImageFromGallery(BuildContext context) async {
    try {
      final avatar = await onPickGallery?.call();
      if (avatar != null && context.mounted) Navigator.pop(context, avatar);
    } catch (_) {
      if (context.mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              UserStorage.l10n.chooseAvatar,
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            if (currentAvatar.isNotEmpty) ...[
              CharacterAvatar(
                avatar: currentAvatar,
                name: currentAvatar,
                size: 64,
              ),
              const SizedBox(height: 4),
              Text(
                UserStorage.l10n.avatarPicker.currentAvatar,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 16),
            ],
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: _avatarOptions
                  .where((avatar) => avatar != currentAvatar)
                  .map((avatar) {
                final name = avatar
                    .split('/')
                    .last
                    .replaceAll('.png', '')
                    .replaceAll('_', ' ');
                return Semantics(
                  button: true,
                  label: name,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, avatar),
                    child: Padding(
                      padding: const EdgeInsets.all(3),
                      child: CharacterAvatar(
                        avatar: avatar,
                        name: name,
                        size: 56,
                        backgroundColor: AppColors.surface,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            if (onPickGallery != null) ...[
              const SizedBox(height: 16),
              ListTile(
                leading:
                    const Icon(Icons.photo_library, color: AppColors.primary),
                title: Text(UserStorage.l10n.selectFromAlbum),
                onTap: () => _pickImageFromGallery(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
