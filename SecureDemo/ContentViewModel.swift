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
    
    @Published var isLoadingButton1: Bool = false
    @Published var isLoadingButton2: Bool = false
    @Published var isLoadingButton3: Bool = false

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
        isLoadingButton1 = true
        Task {
            await dependencies.session.postRequestOne {
                DispatchQueue.main.async { [weak self] in
                    self?.isLoadingButton1 = false
                }
            }
        }
    }
    
    func buttonTwoPressed() {
        isLoadingButton2 = true
        Task {
            await dependencies.session.postRequestTwo { response in
                print("=== ===> button two pressed and got response: \(response)")
                DispatchQueue.main.async { [weak self] in
                    self?.isLoadingButton2 = false
                }
            }
        }
    }
    
    func buttonThreePressed() {
        isLoadingButton3 = true
        Task {
            await dependencies.session.postRequestThree {
                DispatchQueue.main.async { [weak self] in
                    self?.isLoadingButton3 = false
                }
            }
        }
    }
}
