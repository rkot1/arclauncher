// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get aboutFlauncher => 'Acerca de FLauncher';

  @override
  String get addCategory => 'Agregar categoría';

  @override
  String get addSection => 'Agregar sección';

  @override
  String get alphabetical => 'Alfabético';

  @override
  String get appCardHighlightAnimation => 'Resaltar aplicaciones';

  @override
  String get showFocusBorders => 'Mostrar bordes de enfoque';

  @override
  String get focusBorderThickness => 'Grosor del borde de enfoque';

  @override
  String get focusBorderThin => 'Sutil (1.0 dp)';

  @override
  String get focusBorderDefault => 'Por defecto (1.5 dp)';

  @override
  String get focusBorderMedium => 'Medio (2.0 dp)';

  @override
  String get focusBorderBold => 'Grueso (3.0 dp)';

  @override
  String get appInfo => 'Datos de la aplicación';

  @override
  String get appKeyClick => 'Sonido al presionar una tecla';

  @override
  String get appearanceSettings => 'Apariencia';

  @override
  String get backgroundBlur => 'Desenfoque de fondo';

  @override
  String get dockBlur => 'Desenfoque del dock';

  @override
  String get dockDarkBackground => 'Fondo oscuro del dock';

  @override
  String get dockBottomGap => 'Space below favorites';

  @override
  String get dockBottomGapNone => 'None';

  @override
  String get dockShadow => 'Sombra del dock';

  @override
  String get applications => 'Aplicaciones';

  @override
  String get autoHideAppBar => 'Ocultar barra de estado automáticamente';

  @override
  String get hideStatusBarInGrid => 'Ocultar barra de estado en la cuadrícula';

  @override
  String get backButtonAction => 'Acción del botón \'Atrás\'';

  @override
  String get category => 'Categoría';

  @override
  String get categories => 'Categorías';

  @override
  String get columnCount => 'Cantidad de columnas';

  @override
  String get date => 'Fecha';

  @override
  String get dateAndTimeFormat => 'Formato de fecha y hora';

  @override
  String get delete => 'Eliminar';

  @override
  String get dialogOptionBackButtonActionDoNothing => 'Nada';

  @override
  String get dialogOptionBackButtonActionShowScreensaver =>
      'Mostrar salvapantallas';

  @override
  String get dialogOptionBackButtonActionShowClock => 'Mostrar reloj';

  @override
  String get dialogTextNoFileExplorer =>
      'Por favor, instale un gestor de archivos para seleccionar una imagen.';

  @override
  String get dialogTitleBackButtonAction =>
      'Elegir la acción del botón \'Atrás\'';

  @override
  String disambiguateCategoryTitle(String title) {
    return '$title (Categoría)';
  }

  @override
  String formattedDate(String dateString) {
    return 'Fecha con formato: $dateString';
  }

  @override
  String formattedTime(String timeString) {
    return 'Hora con formato: $timeString';
  }

  @override
  String get gradient => 'Gradiente';

  @override
  String get favoriteApps => 'Favoritas';

  @override
  String get grid => 'Cuadrícula';

  @override
  String get height => 'Altura';

  @override
  String get hide => 'Ocultar';

  @override
  String get hiddenApplications => 'Aplicaciones ocultas';

  @override
  String get launcherSections => 'Secciones';

  @override
  String get layout => 'Distribución';

  @override
  String get loading => 'Cargando';

  @override
  String get manual => 'Manual';

  @override
  String get modifySection => 'Modificar sección';

  @override
  String get mustNotBeEmpty => 'No debe estar vacío';

  @override
  String get name => 'Nombre';

  @override
  String get newSection => 'Nueva sección';

  @override
  String get noDateFormatSpecified => 'Sin formato de fecha';

  @override
  String get noTimeFormatSpecified => 'Sin formato de hora';

  @override
  String get allApplications => 'Todas las aplicaciones';

  @override
  String get nonTvApplications => 'Otras aplicaciones';

  @override
  String get open => 'Abrir';

  @override
  String get orSelectFormatSpecifiers =>
      'O seleccione especificadores de formato';

  @override
  String get picture => 'Imagen';

  @override
  String removeFrom(String name) {
    return 'Remover de $name';
  }

  @override
  String get renameCategory => 'Renombrar categoría';

  @override
  String get reorder => 'Reordenar';

  @override
  String get row => 'Row';

  @override
  String get rowHeight => 'Row height';

  @override
  String get save => 'Guardar';

  @override
  String get spacer => 'Espaciador';

  @override
  String get spacerMaxHeightRequirement =>
      'Debe ser mayor a cero y menor o igual a 500';

  @override
  String get statusBar => 'Barra de estado';

  @override
  String get settings => 'Ajustes';

  @override
  String get show => 'Mostrar';

  @override
  String get showCategoryTitles => 'Mostrar títulos de categorías';

  @override
  String get sort => 'Orden';

  @override
  String get systemSettings => 'Ajustes del sistema';

  @override
  String get updateCheck => 'Buscar actualizaciones';

  @override
  String get updateNoUpdateTitle => 'No hay actualizaciones';

  @override
  String updateNoUpdateBody(String currentVersion) {
    return 'Ya tienes la última versión ($currentVersion).';
  }

  @override
  String get updateAvailableTitle => 'Actualización disponible';

  @override
  String updateAvailableBody(String latestVersion, String currentVersion) {
    return 'La versión $latestVersion está disponible (actual: $currentVersion).';
  }

  @override
  String get updateChangelog => 'Novedades';

  @override
  String get updateDownloadButton => 'Descargar';

  @override
  String get updateReadyToInstallTitle => 'Lista para instalar';

  @override
  String updateReadyToInstallBody(String latestVersion) {
    return 'El APK de la versión $latestVersion ya se descargó. ¿Instalar ahora?';
  }

  @override
  String get updateInstallButton => 'Instalar';

  @override
  String get updateInstallPermissionTitle =>
      'Se requiere permiso de instalación';

  @override
  String get updateInstallPermissionBody =>
      'Permite que Arc Launcher instale apps desconocidas y vuelve a intentar la actualización.';

  @override
  String get updateOpenPermissionSettingsButton => 'Abrir ajustes de permisos';

  @override
  String get updateErrorGeneric =>
      'La actualización falló. Inténtalo de nuevo.';

  @override
  String textAboutDialog(String repoUrl) {
    return 'Arc Launcher es un lanzador de código abierto personalizado para Android TV, basado en FLauncher.\n\nDesarrollado por Meddouri Badis.\nCódigo fuente disponible en $repoUrl.';
  }

  @override
  String get textEmptyCategory => 'Esta categoría está vacía.';

  @override
  String get time => 'Hora';

  @override
  String get titleStatusBarSettingsPage =>
      'Elija la información a mostrar en la barra de estado';

  @override
  String get tvApplications => 'Aplicaciones del televisor';

  @override
  String get type => 'Tipo';

  @override
  String get typeInTheDateFormat => 'Escriba el formato de fecha';

  @override
  String get typeInTheHourFormat => 'Escriba el formato de hora';

  @override
  String get uninstall => 'Desinstalar';

  @override
  String get wallpaper => 'Fondo de pantalla';

  @override
  String get withEllipsisAddTo => 'Añadir a...';

  @override
  String get timeBasedWallpaper => 'Fondo de pantalla según la hora';

  @override
  String get unsplashSlideshow => 'Presentación de Unsplash';

  @override
  String get unsplashEnable => 'Mostrar fotos de Unsplash';

  @override
  String get unsplashAccessKey => 'Clave de acceso de Unsplash';

  @override
  String get unsplashAccessKeyHelp =>
      'Crea una app gratuita en unsplash.com/developers y pega su Access Key.';

  @override
  String get unsplashNotSet => 'Sin configurar';

  @override
  String get unsplashInterval => 'Cambiar cada';

  @override
  String unsplashIntervalMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get slideshowCategories => 'Categorías';

  @override
  String get slideshowDay => 'Día (6:00 - 18:00)';

  @override
  String get slideshowNight => 'Noche (18:00 - 6:00)';

  @override
  String unsplashPhotoCredit(String author) {
    return 'Foto: $author / Unsplash';
  }

  @override
  String get pickDayWallpaper => 'Elegir fondo de día';

  @override
  String get pickNightWallpaper => 'Elegir fondo de noche';

  @override
  String get video => 'Vídeo';

  @override
  String get pickDayVideoWallpaper => 'Elegir vídeo de día';

  @override
  String get pickNightVideoWallpaper => 'Elegir vídeo de noche';

  @override
  String get watchNextSectionTitle => 'Ver después';

  @override
  String get showWatchNextSection => 'Mostrar sección Ver después';

  @override
  String get watchNextPermissionTitle => 'Se requiere permiso para Ver después';

  @override
  String get watchNextPermissionBody =>
      'Permite el acceso a la guía de TV para mostrar lo que estabas viendo.';

  @override
  String get watchNextGrantPermission => 'Conceder permiso';

  @override
  String get watchNextCheckPermission => 'Comprobar de nuevo';

  @override
  String get interface => 'Interfaz';

  @override
  String get system => 'Sistema';

  @override
  String get accentColor => 'Color de acento';

  @override
  String get miscellaneous => 'Varios';

  @override
  String get brightnessScheduler => 'Programador de brillo';

  @override
  String get screensaverSettings => 'Ajustes del salvapantallas';

  @override
  String get screensaverClockStyle => 'Estilo del reloj del salvapantallas';

  @override
  String get wifiUsagePeriod => 'Período de uso de WiFi';

  @override
  String get showAppNamesBelowIcons => 'Mostrar nombres bajo los iconos';

  @override
  String get wifiUsage => 'Uso de WiFi';

  @override
  String get networkIndicator => 'Indicador de red';

  @override
  String get customName => 'Nombre personalizado';

  @override
  String get lastUsed => 'Último uso';

  @override
  String get daily => 'Diario';

  @override
  String get weekly => 'Semanal';

  @override
  String get monthly => 'Mensual';

  @override
  String get grantPermission => 'Conceder permiso';

  @override
  String get checkStatus => 'Comprobar estado';

  @override
  String get watchNextBigPictureMode => 'Modo inmersivo';

  @override
  String get watchNextBigPictureModeDescription =>
      'Mostrar fondo de pantalla completa con un botón de ver';

  @override
  String get watchNextWatch => 'Ver';

  @override
  String get watchNextResume => 'Reanudar';

  @override
  String get watchNextRefresh => 'Actualizar contenido';

  @override
  String get watchNextRefreshDescription =>
      'Recargar recomendaciones de los proveedores multimedia';

  @override
  String get watchNextRefreshed => 'Contenido de Seguir viendo actualizado';

  @override
  String get watchNextFilterApps => 'Filtrar aplicaciones';

  @override
  String get watchNextFilterAppsDescription =>
      'Selecciona qué aplicaciones pueden mostrar contenido en Seguir viendo';

  @override
  String get watchNextNoApps =>
      'Ninguna aplicación multimedia proporciona contenido actualmente';

  @override
  String get watchNextShowAllApps =>
      'Mostrar todas las aplicaciones instaladas';

  @override
  String get watchNextHideWithoutImages => 'Ocultar programas sin imagen';

  @override
  String get watchNextHideWithoutImagesDescription =>
      'Mostrar solo programas que incluyan póster o imagen de fondo';

  @override
  String get watchNextMaxItems => 'Máximo de programas';

  @override
  String get watchNextMaxItemsDescription =>
      'Limitar el número de programas mostrados en Seguir viendo';

  @override
  String get watchNextMaxItemsUnlimited => 'Ilimitado';

  @override
  String get redditWallpaper => 'Fondo de Reddit';

  @override
  String get redditWallpaperEnable => 'Mostrar fotos de Reddit';

  @override
  String get redditSubreddits => 'Subreddits';

  @override
  String get redditSort => 'Ordenar por';

  @override
  String get redditSortHot => 'Popular';

  @override
  String get redditSortTopDay => 'Destacados (Hoy)';

  @override
  String get redditSortTopWeek => 'Destacados (Semana)';

  @override
  String get redditSortTopMonth => 'Destacados (Mes)';

  @override
  String get redditSortTopAll => 'Destacados (Siempre)';

  @override
  String get redditSortNew => 'Nuevos';

  @override
  String get redditInterval => 'Cambiar cada';

  @override
  String redditIntervalMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get redditInterval1Hour => '1 hora';

  @override
  String redditIntervalHours(int hours) {
    return '$hours horas';
  }

  @override
  String get redditInterval1Day => '1 día';

  @override
  String redditIntervalDays(int days) {
    return '$days días';
  }

  @override
  String get redditClientId => 'ID de cliente de Reddit (opcional)';

  @override
  String get redditClientIdHelp =>
      'Opcional. Crea una app instalada en reddit.com/prefs/apps y pega su ID.';

  @override
  String get redditChangeNow => 'Cambiar fondo ahora';

  @override
  String get redditAddSubreddit => 'Añadir subreddit personalizado';

  @override
  String get redditSubredditName => 'Nombre del subreddit (sin r/)';

  @override
  String get redditSubredditAdded => 'Subreddit añadido';

  @override
  String get redditSubredditInvalid =>
      'Introduce un nombre de subreddit válido';

  @override
  String get redditWallpaperUpdated =>
      'Fondo de pantalla actualizado con éxito';

  @override
  String get redditWallpaperFailed =>
      'Error al obtener el fondo. Si persiste, añade un ID de cliente de Reddit en los ajustes.';

  @override
  String get addToFavorites => 'Add to Fav';

  @override
  String get removeFromFavorites => 'Remove from Fav';

  @override
  String get addToCategory => 'Add to Category';

  @override
  String get setCustomBanner => 'Set Custom Banner';

  @override
  String get clearCustomBanner => 'Clear Custom Banner';

  @override
  String customBannerSetFailed(String error) {
    return 'Failed to set banner: $error';
  }

  @override
  String customBannerClearFailed(String error) {
    return 'Failed to clear banner: $error';
  }

  @override
  String get selectImage => 'Select Image';

  @override
  String get selectVideo => 'Select Video';

  @override
  String mediaItemCount(int count) {
    return '$count items';
  }

  @override
  String get noImagesFound => 'No images found on device';

  @override
  String get noVideosFound => 'No videos found on device';

  @override
  String get mediaNavigationHint => 'D-pad: navigate  •  Back: cancel';

  @override
  String get mediaSelectionHint =>
      'D-pad: navigate  •  Select: set wallpaper  •  Back: cancel';

  @override
  String get mediaPermissionRequired => 'Media access permission is required';

  @override
  String get mediaPermissionHelp =>
      'Grant permission to browse photos and videos';

  @override
  String get preview => 'Preview';

  @override
  String get colorPurple => 'Purple';

  @override
  String get colorTeal => 'Teal';

  @override
  String get colorBlue => 'Blue';

  @override
  String get colorOrange => 'Orange';

  @override
  String get colorPink => 'Pink';

  @override
  String get colorGreen => 'Green';

  @override
  String get colorWhite => 'White';

  @override
  String get colorYellow => 'Yellow';

  @override
  String get colorRed => 'Red';

  @override
  String get colorCyan => 'Cyan';

  @override
  String get colorIndigo => 'Indigo';

  @override
  String get colorLime => 'Lime';

  @override
  String get colorAmber => 'Amber';

  @override
  String get colorRose => 'Rose';

  @override
  String get colorIceBlue => 'Ice Blue';

  @override
  String get clockStyleMinimal => 'Minimal';

  @override
  String get clockStyleMinimalDescription => 'Thin, elegant font (Default)';

  @override
  String get clockStyleBold => 'Bold';

  @override
  String get clockStyleBoldDescription => 'Thick, highly visible font';

  @override
  String get clockStyleRetro => 'Retro';

  @override
  String get clockStyleRetroDescription => 'Monospaced, retro terminal style';

  @override
  String get clockStyleElegant => 'Elegant';

  @override
  String get clockStyleElegantDescription => 'Classic serif typeface';

  @override
  String get clockStyleNeon => 'Neon';

  @override
  String get clockStyleNeonDescription => 'Ultra-thin, glowing style';

  @override
  String get clockStylePixel => 'Pixel';

  @override
  String get clockStylePixelDescription => 'Bold monospaced, arcade feel';

  @override
  String get clockStyleDigital => 'Digital';

  @override
  String get clockStyleDigitalDescription => 'Clean monospaced display';

  @override
  String get brightnessPermissionRequired => 'Permission Required';

  @override
  String get brightnessPermissionHelp =>
      'To control brightness on this device, you must grant permission via ADB:';

  @override
  String get brightnessExperimentalNotice =>
      'EXPERIMENTAL: This feature is untested and may be removed in future versions based on user feedback.';

  @override
  String get brightnessDeviceSupportNote =>
      'Note: Some Android TV devices may not support app-level brightness control.';

  @override
  String get enableBrightnessScheduler => 'Enable Scheduler';

  @override
  String currentBrightnessSlot(String slot) {
    return 'Current: $slot';
  }

  @override
  String get brightnessSlotMorning => '6 AM - 9 AM';

  @override
  String get brightnessSlotDay => '9 AM - 3 PM';

  @override
  String get brightnessSlotAfternoon => '3 PM - 6 PM';

  @override
  String get brightnessSlotEvening => '6 PM - 10 PM';

  @override
  String get brightnessSlotNight => '10 PM - 6 AM';

  @override
  String get appIconsSettings => 'App Icons';

  @override
  String get appCaptionsSettings => 'App Captions';

  @override
  String get appCardImageMode => 'Card content';

  @override
  String get cardModeBanner => 'Banners';

  @override
  String get cardModeBannerOrIcon => 'Banners, else icon';

  @override
  String get cardModeIcon => 'Icons only';

  @override
  String get appIconVariant => 'Icon';

  @override
  String get iconVariantFull => 'Full icon';

  @override
  String get iconVariantForeground => 'Foreground layer';

  @override
  String get iconVariantMonochrome => 'Monochrome';

  @override
  String get appIconSize => 'Icon size';

  @override
  String get sizeSmall => 'Small';

  @override
  String get sizeMedium => 'Medium';

  @override
  String get sizeLarge => 'Large';

  @override
  String get appIconTint => 'Icon tint';

  @override
  String get iconColor => 'Icon color';

  @override
  String get appCardBackground => 'Background';

  @override
  String get backgroundSolidColor => 'Solid color';

  @override
  String get backgroundGradient => 'Gradient';

  @override
  String get backgroundWallpaperColors => 'Wallpaper colors';

  @override
  String get backgroundTranslucent => 'Translucent';

  @override
  String get backgroundImage => 'Image';

  @override
  String get backgroundChooseImage => 'Choose background image';

  @override
  String get backgroundNoImage => 'No image selected';

  @override
  String get appCardShadow => 'Card shadow';

  @override
  String get appIconsHint =>
      'Icons are pulled from each app package. Foreground layer and Monochrome need adaptive or themed icons; other apps keep their full icon. Custom banners always win.';

  @override
  String get captionVisibility => 'Show captions';

  @override
  String get captionVisibilityHidden => 'Never';

  @override
  String get captionVisibilityAlways => 'Always';

  @override
  String get captionVisibilityFocused => 'When focused';

  @override
  String get captionPosition => 'Position';

  @override
  String get captionPositionBelow => 'Below card';

  @override
  String get captionPositionOverlay => 'On card';

  @override
  String get captionFont => 'Font';

  @override
  String get captionFontDefault => 'Default';

  @override
  String get captionImportFont => 'Import font file';

  @override
  String captionImportFontHint(String path) {
    return 'Or copy .ttf / .otf files to $path';
  }

  @override
  String get captionFontSize => 'Size';

  @override
  String get captionFontWeight => 'Weight';

  @override
  String get fontWeightLight => 'Light';

  @override
  String get fontWeightRegular => 'Regular';

  @override
  String get fontWeightMedium => 'Medium';

  @override
  String get fontWeightSemiBold => 'Semi-bold';

  @override
  String get fontWeightBold => 'Bold';

  @override
  String get fontWeightBlack => 'Black';

  @override
  String get captionLetterCase => 'Letter case';

  @override
  String get captionCaseNormal => 'Normal';

  @override
  String get captionCaseUppercase => 'UPPERCASE';

  @override
  String get captionAlignment => 'Alignment';

  @override
  String get captionAlignStart => 'Start';

  @override
  String get captionAlignCenter => 'Center';

  @override
  String get captionColor => 'Color';

  @override
  String get captionColorTheme => 'Theme';

  @override
  String get captionColorMuted => 'Muted';

  @override
  String get captionColorAccent => 'Accent';

  @override
  String get captionBackground => 'Background';

  @override
  String get captionBackgroundPill => 'Pill';

  @override
  String get captionBackgroundBar => 'Bar';

  @override
  String get captionTextShadow => 'Text shadow';

  @override
  String get captionBoxShadow => 'Box shadow';

  @override
  String get styleNone => 'None';

  @override
  String get shadowDefault => 'Default';

  @override
  String get shadowSoft => 'Soft';

  @override
  String get shadowStrong => 'Strong';

  @override
  String get shadowOutline => 'Outline';

  @override
  String get shadowGlow => 'Accent glow';

  @override
  String get systemNavigationBar => 'System navigation bar';

  @override
  String get navigationBarVisible => 'Always visible';

  @override
  String get navigationBarHidden => 'Hidden, swipe up';

  @override
  String get navigationBarBottomEdge => 'Show at bottom edge';

  @override
  String get backupSettings => 'Backup & restore';

  @override
  String get backupExport => 'Export settings & layout';

  @override
  String get backupExportHint => 'Saves a JSON file in the backups folder';

  @override
  String get backupSaveCopy => 'Save a copy to…';

  @override
  String get backupSaveCopyHint => 'Pick a place such as a USB drive';

  @override
  String get backupRestoreFromFile => 'Restore from file…';

  @override
  String get backupSavedBackups => 'Saved backups';

  @override
  String get backupNoBackups => 'No backups yet';

  @override
  String get backupBeforeRestore => 'Saved before the last restore';

  @override
  String backupSavedTo(String path) {
    return 'Saved to $path';
  }

  @override
  String get backupCopySaved => 'Copy saved';

  @override
  String get backupSaveUnavailable =>
      'No app on this device can save files. Copy backups from the folder below with adb instead.';

  @override
  String get backupOpenUnavailable =>
      'No app on this device can open files. Copy the file into the folder below instead.';

  @override
  String get backupRestoreTitle => 'Restore this backup?';

  @override
  String backupRestoreBody(String undoFile) {
    return 'Your settings and layout will be replaced. The current ones are saved first as $undoFile, so you can go back.';
  }

  @override
  String get backupRestore => 'Restore';

  @override
  String get backupRestored => 'Backup restored';

  @override
  String backupRestoredSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Backup restored. $count apps aren\'t installed here and were skipped.',
      one: 'Backup restored. 1 app isn\'t installed here and was skipped.',
    );
    return '$_temp0';
  }

  @override
  String backupRestoreFailed(String error) {
    return 'Couldn\'t restore: $error';
  }

  @override
  String backupExportFailed(String error) {
    return 'Couldn\'t save: $error';
  }

  @override
  String backupFolderHint(String path) {
    return 'Backups folder: $path';
  }

  @override
  String backupAdbHint(String package) {
    return 'Tune settings from a computer: adb shell am broadcast -a $package.COMMAND --es cmd help';
  }
}
