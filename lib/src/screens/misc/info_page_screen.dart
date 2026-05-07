import 'package:flutter/material.dart';

import '../../ui/navigation/shop_layer_app_bar.dart';

enum InfoPageKey {
  about,
  delivery,
  payment,
  returns,
  privacy,
  support,
}

class InfoPageScreen extends StatelessWidget {
  const InfoPageScreen({
    super.key,
    required this.page,
  });

  final InfoPageKey page;

  @override
  Widget build(BuildContext context) {
    final (title, blocks) = _content(page);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: shopLayerAppBarActions(context),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          for (final b in blocks) ...[
            _BlockCard(block: b),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _InfoBlock {
  const _InfoBlock(this.title, this.body);
  final String title;
  final String body;
}

class _BlockCard extends StatelessWidget {
  const _BlockCard({required this.block});
  final _InfoBlock block;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            block.title,
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          SelectableText(
            block.body,
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.78),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

(String, List<_InfoBlock>) _content(InfoPageKey page) {
  switch (page) {
    case InfoPageKey.about:
      return (
        'О нас',
        const [
          _InfoBlock(
            'Кто мы',
            'Savdo.tech — магазин автохимии и бытовой химии. '
            'Через приложение вы можете выбирать товары, оформлять заказы и следить за статусом.',
          ),
          _InfoBlock(
            'Цены и ассортимент',
            'Ассортимент и цены в приложении могут меняться без предварительного уведомления. '
            'Актуальная информация отображается в карточке товара и при оформлении заказа.',
          ),
          _InfoBlock(
            'MLM (если подключено)',
            'Раздел MLM предназначен для участников партнёрской программы. '
            'Доступность функций зависит от настроек аккаунта и правил программы.',
          ),
        ],
      );

    case InfoPageKey.delivery:
      return (
        'Условия доставки',
        const [
          _InfoBlock(
            'Бесплатная доставка',
            'Бесплатная доставка может быть доступна при выполнении условий магазина '
            '(например, минимальная сумма заказа, зона доставки или пункт выдачи).',
          ),
          _InfoBlock(
            'Сроки',
            'Срок доставки зависит от города/района и загруженности. '
            'Точную информацию можно уточнить у поддержки после оформления заказа.',
          ),
          _InfoBlock(
            'Пункт выдачи / курьер',
            'В некоторых случаях заказ доставляется в пункт выдачи. '
            'Если доступна курьерская доставка — условия будут сообщены при подтверждении заказа.',
          ),
          _InfoBlock(
            'Проверка заказа',
            'При получении рекомендуем проверить упаковку и комплектность. '
            'Если есть проблема — сразу сообщите в поддержку.',
          ),
        ],
      );

    case InfoPageKey.payment:
      return (
        'Как оплатить',
        const [
          _InfoBlock(
            'Способы оплаты',
            'Оплата может быть доступна: при получении (наличными/картой) или онлайн, '
            'в зависимости от региона и настроек магазина.',
          ),
          _InfoBlock(
            'Подтверждение оплаты',
            'После оформления заказа вы увидите подтверждение в разделе «Мои заказы». '
            'Если выбран онлайн‑платёж и он не прошёл — заказ может остаться в статусе «Создан».',
          ),
          _InfoBlock(
            'Безопасность',
            'Платёжные данные обрабатываются платёжным провайдером. '
            'Приложение не хранит данные банковских карт на устройстве.',
          ),
        ],
      );

    case InfoPageKey.returns:
      return (
        'Возврат',
        const [
          _InfoBlock(
            'Проверка при получении',
            'Рекомендуем проверить заказ при получении: целостность упаковки, количество, '
            'соответствие товара и срок годности (если применимо).',
          ),
          _InfoBlock(
            'Если товар не подходит / брак',
            'Если товар ненадлежащего качества или не соответствует заказу — обратитесь в поддержку. '
            'Мы подскажем порядок возврата/обмена согласно законодательству Республики Таджикистан.',
          ),
          _InfoBlock(
            'Возврат денежных средств',
            'Срок и способ возврата зависят от способа оплаты и процедуры подтверждения возврата. '
            'После принятия решения магазином возврат производится тем же способом, которым была выполнена оплата '
            '(если иное не предусмотрено правилами и законом).',
          ),
        ],
      );

    case InfoPageKey.privacy:
      return (
        'Политика конфиденциальности',
        const [
          _InfoBlock(
            'Какие данные мы обрабатываем',
            'Для работы приложения могут обрабатываться: номер телефона, имя/фамилия, адрес доставки, '
            'история заказов, а также технические данные (например, информация об устройстве, журнал ошибок).',
          ),
          _InfoBlock(
            'Цели обработки',
            'Данные используются для: регистрации и входа, оформления и доставки заказов, поддержки, '
            'уведомлений, предотвращения злоупотреблений и улучшения качества сервиса.',
          ),
          _InfoBlock(
            'Передача третьим лицам',
            'Данные могут передаваться только в объёме, необходимом для выполнения услуг: '
            'службам доставки, платёжным провайдерам, сервисам уведомлений. '
            'Мы не продаём персональные данные.',
          ),
          _InfoBlock(
            'Хранение и защита',
            'Мы применяем организационные и технические меры для защиты данных. '
            'Срок хранения зависит от целей обработки и требований закона.',
          ),
          _InfoBlock(
            'Ваши права',
            'Вы можете запросить доступ, исправление или удаление ваших данных, а также отказаться от '
            'маркетинговых уведомлений (если включены). Для запросов используйте раздел «Поддержка».',
          ),
        ],
      );

    case InfoPageKey.support:
      return (
        'Поддержка',
        const [
          _InfoBlock(
            'Как связаться',
            'Напишите нам по вопросам заказа, оплаты, возврата и работы приложения. '
            'Контакты поддержки могут быть указаны на сайте `savdo.tech` или предоставлены менеджером.',
          ),
          _InfoBlock(
            'Что указать в обращении',
            'Укажите: номер телефона аккаунта, номер заказа (если есть), краткое описание проблемы '
            'и при необходимости скриншоты.',
          ),
          _InfoBlock(
            'Срок ответа',
            'Мы стараемся отвечать как можно быстрее в рабочее время.',
          ),
        ],
      );
  }
}
