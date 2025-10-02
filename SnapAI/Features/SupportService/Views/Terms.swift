//
//  Terms.swift
//  SnapAI
//
//  Created by Isa Melsov on 2/10/25.
//

import SwiftUI

// MARK: - Shared building blocks

struct LegalSection: Identifiable {
    let id = UUID()
    let title: String
    let items: [String]
}

struct BulletRowTerms: View {
    let text: String
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text("•")
                .font(.headline)
                .foregroundStyle(AppColors.primary)     // ваш стиль
            Text(text)
                .foregroundStyle(AppColors.primary)     // ваш стиль
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct LegalBulletListView: View {
    let title: String
    let sections: [LegalSection]
    var footer: String? = nil
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                // Голый текст: заголовки секций + буллеты
                ForEach(sections.indices, id: \.self) { i in
                    let s = sections[i]

                    Text(s.title)
                        .font(.headline)
                        .foregroundStyle(AppColors.primary)
                        .padding(.top, i == 0 ? 0 : 4)

                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(s.items, id: \.self) { item in
                            BulletRowTerms(text: item) // "•  текст"
                        }
                    }

                    if i != sections.indices.last {
                        Divider().opacity(0.2) // тонкий разделитель между секциями
                    }
                }

                // Футер в самом низу по центру
                if let footer {
                    Text(footer)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                }
            }
            .padding(16)
        }
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: { dismiss() }) {
                    AppImages.ButtonIcons.arrowRight
                        .resizable()
                        .scaledToFill()
                        .frame(width: 12, height: 12)
                        .rotationEffect(.degrees(180))
                        .padding(12)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            
            ToolbarItem(placement: .topBarLeading) {
                Text(title)
                    .foregroundStyle(AppColors.primary)
                    .bold()
                    .font(.largeTitle)
            }
            
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Privacy Policy screen

struct PrivacyPolicyScreen: View {
    let appName: String
    let company: String
    let email: String
    let effectiveDate: String

    var body: some View {
        LegalBulletListView(
            title: "Privacy Policy",
            sections: [
                .init(
                    title: "Какие данные собираем",
                    items: [
                        "Имя, email, телефон — когда вы их указываете.",
                        "Текст обращений и прикреплённые изображения.",
                        "Технические метаданные: модель устройства, версия ОС, язык, IP, лог ошибок.",
                        "Данные об использовании \(appName): экраны, клики, длительность сессий.",
                        "Cookies/SDK-теги — для аналитики и аутентификации."
                    ]
                ),
                .init(
                    title: "Зачем используем",
                    items: [
                        "Работа функций приложения и поддержка пользователей.",
                        "Аналитика и улучшение стабильности/безопасности.",
                        "Сервисные уведомления.",
                        "Маркетинг — только по вашему согласию (его можно отозвать)."
                    ]
                ),
                .init(
                    title: "С кем делимся",
                    items: [
                        "Провайдеры-обработчики (хостинг, аналитика, почта, платёжные сервисы) по договору и по минимуму.",
                        "Госорганы — только если этого требует закон.",
                        "Мы не продаём персональные данные."
                    ]
                ),
                .init(
                    title: "Хранение и безопасность",
                    items: [
                        "Храним ровно столько, сколько нужно по целям или закону.",
                        "Шифрование при передаче/хранении, ограничение доступа, организационные меры."
                    ]
                ),
                .init(
                    title: "Международные передачи",
                    items: [
                        "Данные могут обрабатываться на серверах за пределами вашей страны.",
                        "Используем юридические механизмы (SCC и др.) для защиты."
                    ]
                ),
                .init(
                    title: "Ваши права",
                    items: [
                        "Доступ/копия, исправление, удаление, ограничение обработки.",
                        "Возражение против обработки, отзыв согласия.",
                        "Переносимость данных и жалоба регулятору.",
                        "Запросы — на \(email)."
                    ]
                ),
                .init(
                    title: "Дети",
                    items: [
                        "\(appName) не предназначено для детей младше 13/16 лет (укажите нужный порог)."
                    ]
                ),
                .init(
                    title: "Изменения политики",
                    items: [
                        "Будем обновлять текст в приложении, укажем новую дату вступления.",
                        "Существенные изменения — с заметным уведомлением."
                    ]
                ),
                .init(
                    title: "Контакты",
                    items: [
                        "Вопросы по приватности: \(email) (тема: Privacy)."
                    ]
                )
            ],
            footer: "\(company) • Effective: \(effectiveDate)"
        )
    }
}

// MARK: - Terms of Service screen

struct TermsOfServiceScreen: View {
    let appName: String
    let company: String
    let email: String
    let effectiveDate: String

    var body: some View {
        LegalBulletListView(
            title: "Terms of Service",
            sections: [
                .init(
                    title: "Акцепт и изменения",
                    items: [
                        "Устанавливая и используя \(appName), вы принимаете Условия.",
                        "Мы можем обновлять текст; действует версия в приложении/на сайте."
                    ]
                ),
                .init(
                    title: "Использование сервиса",
                    items: [
                        "Только законные цели; не нарушать права третьих лиц.",
                        "Запрещено спамить, распространять вредоносный код, обходить ограничения и получать несанкционированный доступ."
                    ]
                ),
                .init(
                    title: "Учётная запись",
                    items: [
                        "Вы отвечаете за точность данных и безопасность доступа к аккаунту/устройству.",
                        "Сообщайте о несанкционированном доступе незамедлительно."
                    ]
                ),
                .init(
                    title: "Контент пользователя",
                    items: [
                        "Права на контент сохраняются за вами.",
                        "Вы предоставляете нам неисключительную лицензию на хранение/обработку для работы сервиса и поддержки.",
                        "Вы гарантируете наличие прав на загружаемый контент."
                    ]
                ),
                .init(
                    title: "Платные функции (если есть)",
                    items: [
                        "Цена, периодичность и автопродление — в приложении/магазине.",
                        "Оплата через платформу (App Store и др.); возвраты по правилам платформы и нашей политике.",
                        "Отменять подписку — в настройках аккаунта платформы."
                    ]
                ),
                .init(
                    title: "Интеллектуальная собственность",
                    items: [
                        "Код, дизайн и базы данных принадлежат \(company) и/или лицензиарам.",
                        "Лицензия — ограниченная, отменяемая, непередаваемая, неэксклюзивная для личного пользования."
                    ]
                ),
                .init(
                    title: "Отказ от гарантий",
                    items: [
                        "\(appName) предоставляется «как есть» и «как доступно».",
                        "Мы не гарантируем отсутствие ошибок или соответствие конкретным ожиданиям."
                    ]
                ),
                .init(
                    title: "Ограничение ответственности",
                    items: [
                        "Без косвенных/случайных убытков, упущенной выгоды и потери данных.",
                        "Лимит ответственности — сумма, уплаченная за последние 12 месяцев (или укажите фикс)."
                    ]
                ),
                .init(
                    title: "Прекращение",
                    items: [
                        "Мы можем приостановить/закрыть доступ при нарушениях или по требованию закона.",
                        "Вы можете прекратить использование в любой момент."
                    ]
                ),
                .init(
                    title: "Применимое право и споры",
                    items: [
                        "Регулируется правом [укажите юрисдикцию].",
                        "Споры — в судах [юрисдикция] или по ADR, если применимо."
                    ]
                ),
                .init(
                    title: "Связь",
                    items: [
                        "По вопросам Условий: \(email) (тема: Terms)."
                    ]
                )
            ],
            footer: "\(company) • Effective: \(effectiveDate)"
        )
    }
}

// MARK: - Previews

#Preview("Privacy") {
    NavigationStack {
        PrivacyPolicyScreen(appName: "SnapAI",
                            company: "SnapAI",
                            email: "support@example.com",
                            effectiveDate: "01.10.2025")
    }
}

#Preview("Terms") {
    NavigationStack {
        TermsOfServiceScreen(appName: "SnapAI",
                             company: "SnapAI",
                             email: "support@example.com",
                             effectiveDate: "01.10.2025")
    }
}
