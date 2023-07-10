//
//  UserService.swift
//  SecureDemo
//
//  Created by Maksim Kalik on 7/9/23.
//

import Foundation
import Combine

typealias DisposeBag = Set<AnyCancellable>

class UserService {

    let userSubject = CurrentValueSubject<User?, Never>(nil)
    private let dependencies: Dependencies
    private var disposeBag: DisposeBag = []
    
    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }
    
    // We should start observing user before any secure requests
    func start() {
        subscribeUserSubject()
        prepareUser()
    }

    private var user: User? {
        get { userSubject.value }
        set { userSubject.send(newValue) }
    }
    
    private func prepareUser() {
        dependencies.server.fetchMockedUser { user in
            self.user = user
            self.observeUser()
        }
    }
    
    private func observeUser() {
        dependencies.server.observeUser { user in
            self.user = user
        }
    }
    
    private func subscribeUserSubject() {
        userSubject
            .scan((nil, nil)) { ($0.1, $1) }
            .sink { (old, new) in
                guard let newRandom = new?.random, old?.random != newRandom else { return }
                self.dependencies.secure.executeFromQueue(newRandom)
                self.dependencies.secureCombine.executeFromQueue(newRandom)
            }
            .store(in: &disposeBag)
    }
}
