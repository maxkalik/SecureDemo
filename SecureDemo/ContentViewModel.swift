//
//  ContentViewModel.swift
//  SecureDemo
//
//  Created by Maksim Kalik on 1/16/23.
//

import Foundation

class ContentViewModel: ObservableObject {

    private let dependencies = AppDependencies()
    @Published var isLoading: Bool = true

    init() {
        Task {
            await dependencies.session.prepareSession()
            await MainActor.run {
                isLoading = false
            }
            await dependencies.session.observeUser()
        }
    }
    
    func buttonOnePressed() {
        Task {
            await dependencies.session.postRequestOne()
        }
    }
    
    func buttonTwoPressed() {
        Task {
            await dependencies.session.postRequestTwo()
        }
    }
    
    func buttonThreePressed() {
        Task {
            await dependencies.session.postRequestThree()
        }
    }
}
