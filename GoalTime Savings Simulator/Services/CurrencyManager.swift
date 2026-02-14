import Foundation

// MARK: - 40+ Currency Options

struct CurrencyInfo: Identifiable, Hashable {
    let id: String // ISO code
    let code: String
    let name: String
    let symbol: String
    let flag: String
}

struct CurrencyManager {
    static let currencies: [CurrencyInfo] = [
        CurrencyInfo(id: "USD", code: "USD", name: "US Dollar", symbol: "$", flag: "🇺🇸"),
        CurrencyInfo(id: "EUR", code: "EUR", name: "Euro", symbol: "€", flag: "🇪🇺"),
        CurrencyInfo(id: "GBP", code: "GBP", name: "British Pound", symbol: "£", flag: "🇬🇧"),
        CurrencyInfo(id: "JPY", code: "JPY", name: "Japanese Yen", symbol: "¥", flag: "🇯🇵"),
        CurrencyInfo(id: "CHF", code: "CHF", name: "Swiss Franc", symbol: "CHF", flag: "🇨🇭"),
        CurrencyInfo(id: "CAD", code: "CAD", name: "Canadian Dollar", symbol: "C$", flag: "🇨🇦"),
        CurrencyInfo(id: "AUD", code: "AUD", name: "Australian Dollar", symbol: "A$", flag: "🇦🇺"),
        CurrencyInfo(id: "CNY", code: "CNY", name: "Chinese Yuan", symbol: "¥", flag: "🇨🇳"),
        CurrencyInfo(id: "INR", code: "INR", name: "Indian Rupee", symbol: "₹", flag: "🇮🇳"),
        CurrencyInfo(id: "KRW", code: "KRW", name: "South Korean Won", symbol: "₩", flag: "🇰🇷"),
        CurrencyInfo(id: "BRL", code: "BRL", name: "Brazilian Real", symbol: "R$", flag: "🇧🇷"),
        CurrencyInfo(id: "RUB", code: "RUB", name: "Russian Ruble", symbol: "₽", flag: "🇷🇺"),
        CurrencyInfo(id: "MXN", code: "MXN", name: "Mexican Peso", symbol: "MX$", flag: "🇲🇽"),
        CurrencyInfo(id: "SGD", code: "SGD", name: "Singapore Dollar", symbol: "S$", flag: "🇸🇬"),
        CurrencyInfo(id: "HKD", code: "HKD", name: "Hong Kong Dollar", symbol: "HK$", flag: "🇭🇰"),
        CurrencyInfo(id: "NOK", code: "NOK", name: "Norwegian Krone", symbol: "kr", flag: "🇳🇴"),
        CurrencyInfo(id: "SEK", code: "SEK", name: "Swedish Krona", symbol: "kr", flag: "🇸🇪"),
        CurrencyInfo(id: "DKK", code: "DKK", name: "Danish Krone", symbol: "kr", flag: "🇩🇰"),
        CurrencyInfo(id: "NZD", code: "NZD", name: "New Zealand Dollar", symbol: "NZ$", flag: "🇳🇿"),
        CurrencyInfo(id: "ZAR", code: "ZAR", name: "South African Rand", symbol: "R", flag: "🇿🇦"),
        CurrencyInfo(id: "TRY", code: "TRY", name: "Turkish Lira", symbol: "₺", flag: "🇹🇷"),
        CurrencyInfo(id: "PLN", code: "PLN", name: "Polish Zloty", symbol: "zł", flag: "🇵🇱"),
        CurrencyInfo(id: "THB", code: "THB", name: "Thai Baht", symbol: "฿", flag: "🇹🇭"),
        CurrencyInfo(id: "IDR", code: "IDR", name: "Indonesian Rupiah", symbol: "Rp", flag: "🇮🇩"),
        CurrencyInfo(id: "MYR", code: "MYR", name: "Malaysian Ringgit", symbol: "RM", flag: "🇲🇾"),
        CurrencyInfo(id: "PHP", code: "PHP", name: "Philippine Peso", symbol: "₱", flag: "🇵🇭"),
        CurrencyInfo(id: "CZK", code: "CZK", name: "Czech Koruna", symbol: "Kč", flag: "🇨🇿"),
        CurrencyInfo(id: "ILS", code: "ILS", name: "Israeli Shekel", symbol: "₪", flag: "🇮🇱"),
        CurrencyInfo(id: "CLP", code: "CLP", name: "Chilean Peso", symbol: "CL$", flag: "🇨🇱"),
        CurrencyInfo(id: "AED", code: "AED", name: "UAE Dirham", symbol: "د.إ", flag: "🇦🇪"),
        CurrencyInfo(id: "SAR", code: "SAR", name: "Saudi Riyal", symbol: "﷼", flag: "🇸🇦"),
        CurrencyInfo(id: "TWD", code: "TWD", name: "Taiwan Dollar", symbol: "NT$", flag: "🇹🇼"),
        CurrencyInfo(id: "ARS", code: "ARS", name: "Argentine Peso", symbol: "AR$", flag: "🇦🇷"),
        CurrencyInfo(id: "COP", code: "COP", name: "Colombian Peso", symbol: "CO$", flag: "🇨🇴"),
        CurrencyInfo(id: "EGP", code: "EGP", name: "Egyptian Pound", symbol: "E£", flag: "🇪🇬"),
        CurrencyInfo(id: "NGN", code: "NGN", name: "Nigerian Naira", symbol: "₦", flag: "🇳🇬"),
        CurrencyInfo(id: "PKR", code: "PKR", name: "Pakistani Rupee", symbol: "₨", flag: "🇵🇰"),
        CurrencyInfo(id: "BDT", code: "BDT", name: "Bangladeshi Taka", symbol: "৳", flag: "🇧🇩"),
        CurrencyInfo(id: "VND", code: "VND", name: "Vietnamese Dong", symbol: "₫", flag: "🇻🇳"),
        CurrencyInfo(id: "HUF", code: "HUF", name: "Hungarian Forint", symbol: "Ft", flag: "🇭🇺"),
        CurrencyInfo(id: "RON", code: "RON", name: "Romanian Leu", symbol: "lei", flag: "🇷🇴"),
        CurrencyInfo(id: "UAH", code: "UAH", name: "Ukrainian Hryvnia", symbol: "₴", flag: "🇺🇦"),
        CurrencyInfo(id: "KZT", code: "KZT", name: "Kazakhstani Tenge", symbol: "₸", flag: "🇰🇿"),
        CurrencyInfo(id: "QAR", code: "QAR", name: "Qatari Riyal", symbol: "﷼", flag: "🇶🇦"),
        CurrencyInfo(id: "KWD", code: "KWD", name: "Kuwaiti Dinar", symbol: "د.ك", flag: "🇰🇼"),
    ]
    
    static func currency(for code: String) -> CurrencyInfo? {
        currencies.first { $0.code == code }
    }
    
    static var `default`: CurrencyInfo {
        currencies[0]
    }
}
