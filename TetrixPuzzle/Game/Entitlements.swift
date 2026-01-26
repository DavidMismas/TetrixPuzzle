//
//  Entitlements.swift
//  TetrixPuzzle
//
//  Created by David Mišmaš on 24. 1. 26.
//

import Foundation
import StoreKit
import SwiftUI
import Combine

@MainActor
final class Entitlements: ObservableObject {

    static let proProductID = "com.david.TetrixPuzzle.pro"

    @Published private(set) var isPro: Bool = false
    @Published private(set) var proPrice: String? = nil

    @AppStorage("isProUnlocked") private var cachedIsProUnlocked: Bool = false

    #if DEBUG
    @Published var debugForcePro: Bool = false
    #endif

    func start() {
        isPro = cachedIsProUnlocked

        Task {
            await refresh()
            await loadPrice()
            await listenForTransactions()
        }
    }

    func refresh() async {
        #if DEBUG
        if debugForcePro {
            isPro = true
            cachedIsProUnlocked = true
            return
        }
        #endif

        var unlocked = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if transaction.productID == Self.proProductID {
                unlocked = true
                break
            }
        }

        isPro = unlocked
        cachedIsProUnlocked = unlocked
    }

    func loadPrice() async {
        do {
            let products = try await Product.products(for: [Self.proProductID])
            if let p = products.first {
                proPrice = p.displayPrice
            }
        } catch {
            // ignore
        }
    }

    func buyPro() async -> Bool {
        do {
            let products = try await Product.products(for: [Self.proProductID])
            guard let product = products.first else { return false }

            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                guard case .verified(let transaction) = verification else { return false }
                await transaction.finish()
                await refresh()
                return isPro
            case .userCancelled, .pending:
                return false
            @unknown default:
                return false
            }
        } catch {
            return false
        }
    }

    func restorePurchases() async {
        try? await AppStore.sync()
        await refresh()
    }

    private func listenForTransactions() async {
        for await result in Transaction.updates {
            guard case .verified(let transaction) = result else { continue }
            if transaction.productID == Self.proProductID {
                cachedIsProUnlocked = true
                isPro = true
            }
            await transaction.finish()
        }
    }
}
