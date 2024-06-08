//
//  Product.swift
//  product-bubble
//
//  Created by ほしょ on 2024/06/08.
//

import Foundation

// 構造体定義
struct ProductResponse: Codable {
    let hits: [Product]
}

struct Product: Codable {
    let genreCategory: GenreCategory
    let brand: Brand
    let priceLabel: PriceLabel
    let name: String
    let image: Image
    let price: Double
    let url: String
    let seller: Seller
    let parentGenreCategories: [GenreCategory]
    
    enum CodingKeys: String, CodingKey {
        case genreCategory
        case brand
        case priceLabel
        case name
        case image
        case price
        case url
        case seller
        case parentGenreCategories
    }
}

struct GenreCategory: Codable {
    let name: String
}

struct Brand: Codable {
    let name: String
}

struct PriceLabel: Codable {
    let defaultPrice: Double
}

struct Image: Codable {
    let medium: String
}

struct Seller: Codable {
    let name: String
}
