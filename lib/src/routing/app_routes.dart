class AppRoutes {
  static const String splash = '/';
  static const String home = '/home';
  /// Nested under [main] so bottom shell stays visible.
  static const String notifications = '/home/main/notifications';
  static const String favorites = '/home/main/favorites';
  static const String compare = '/home/main/compare';
  static const String settings = '/home/main/settings';
  static const String infoAbout = '/home/main/info/about';
  static const String infoDelivery = '/home/main/info/delivery';
  static const String infoPayment = '/home/main/info/payment';
  static const String infoReturns = '/home/main/info/returns';
  static const String infoPrivacy = '/home/main/info/privacy';
  static const String infoSupport = '/home/main/info/support';

  static const String main = '/home/main';

  static String productBySlug(String slug) => '/home/main/product/$slug';
  static const String catalog = '/home/catalog';

  /// Маҳсулотҳои категория (зери таби Каталог, футер намоиш дода мешавад).
  static String catalogCategoryProducts(String slug) => '/home/catalog/category/$slug';

  /// Зеркатегорияҳо (зери таби Каталог).
  static String catalogCategoryChildren(String slug) => '/home/catalog/category/$slug/children';
  static const String cart = '/home/cart';
  static const String mlm = '/home/mlm';
  static const String mlmTeamTree = '/home/mlm/tree';
  static const String mlmBonuses = '/home/mlm/bonuses';
  static const String profile = '/home/profile';
  static const String profileMyData = '/home/profile/my-data';
  static const String profileMyOrders = '/home/profile/my-orders';
  static const String profileWallet = '/home/profile/wallet';
}

