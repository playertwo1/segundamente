import 'template_gallery_models.dart';
import 'template_gallery_en.dart';
import 'template_gallery_pt.dart';

typedef TemplateGalleryData = ({
  List<TemplateGallerySection> timelineSections,
  List<TemplateGalleryItem> insightItems,
});

TemplateGalleryData lookupTemplateGallery(String localeName) {
  switch (localeName) {
    case 'pt':
      return (
        timelineSections: timelineTemplateGallerySectionsPt,
        insightItems: insightTemplateGalleryItemsPt,
      );
    case 'en':
    default:
      return (
        timelineSections: timelineTemplateGallerySectionsEn,
        insightItems: insightTemplateGalleryItemsEn,
      );
  }
}
