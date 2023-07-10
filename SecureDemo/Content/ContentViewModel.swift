//
//  ContentViewModel.swift
//  SecureDemo
//
//  Created by Maksim Kalik on 1/16/23.
//

import Foundation
import Combine

class ContentViewModel: ObservableObject {

    private var disposeBag: DisposeBag = []
    private let dependencies = AppDependencies()
    
    @Published var isLoading: Bool = true
    @Published var isLoadingButton1: Bool = false
    @Published var isLoadingButton2: Bool = false
    @Published var isLoadingButton3: Bool = false

    init() {
        dependencies.user.userSubject
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                guard let self else { return }
                self.isLoading = false
            }
            .store(in: &disposeBag)
    }
    
    // MARK: - Button 1
    
    func buttonOnePressed() {
        isLoadingButton1 = true

//        buttonOnePressedSecure()
        buttonOnePressedSecureCombine()
    }
    
    func buttonOnePressedSecure() {
        dependencies.session.postRequestOne {
            DispatchQueue.main.async {
                self.isLoadingButton1 = false
            }
        }
    }
    
    func buttonOnePressedSecureCombine() {
        dependencies.session.postRequestOne()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    print("--------------------- button 1 finished")
                case .failure(let error):
                    print("--------------------- button 1 error", error)
                }
            }, receiveValue: { _ in
                self.isLoadingButton1 = false
            })
            .store(in: &disposeBag)
    }
    
    // MARK: - Button 2
    
    func buttonTwoPressed() {
        isLoadingButton2 = true
        
//        buttonTwoPressedSecure()
        buttonTwoPressedSecureCombine()
    }
    
    func buttonTwoPressedSecure() {
        dependencies.session.postRequestTwo { response in
            if let response {
                print("=== ===> button 2 pressed and got response: \(response)")
            }
            DispatchQueue.main.async {
                self.isLoadingButton2 = false
            }
        }
    }
    
    func buttonTwoPressedSecureCombine() {
        dependencies.session.postRequestTwo()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    print("--------------------- button 2 finished")
                case .failure(let error):
                    print("--------------------- button 2 error", error)
                }
            }, receiveValue: { response in
                print("=== ===> button 2 pressed and got response: \(response)")
                self.isLoadingButton2 = false
            })
            .store(in: &disposeBag)
    }
    
    // MARK: - Button 3
    
    func buttonThreePressed() {
        isLoadingButton3 = true
        
//        buttonThreePressedSecure()
        buttonThreePressedSecureCombine()
    }
    
    func buttonThreePressedSecure() {
        dependencies.session.postRequestThree {
            DispatchQueue.main.async {
                self.isLoadingButton3 = false
            }
        }
    }
    
    func buttonThreePressedSecureCombine() {
        dependencies.session.postRequestThree()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    print("--------------------- button 3 finished")
                case .failure(let error):
                    print("--------------------- button 3 error", error)
                }
            }, receiveValue: { _ in
                self.isLoadingButton3 = false
            })
            .store(in: &disposeBag)
    }
}
