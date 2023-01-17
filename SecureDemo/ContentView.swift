//
//  ContentView.swift
//  SecureDemo
//
//  Created by Maksim Kalik on 1/16/23.
//

import SwiftUI

struct ContentView: View {
    
    @StateObject var viewModel = ContentViewModel()
    
    var body: some View {
        if viewModel.isLoading {
            ProgressView()
        } else {
            VStack {
                Text("Secure Demo")
                    .font(.title)
                
                Spacer()
                    .frame(height: 200)
                
                Button {
                    viewModel.buttonOnePressed()
                } label: {
                    Text("Start Request 1")
                }
                .frame(height: 50)
                
                Button {
                    viewModel.buttonTwoPressed()
                } label: {
                    Text("Start Request 2")
                }
                .frame(height: 50)
                
                Button {
                    viewModel.buttonThreePressed()
                } label: {
                    Text("Start Request 3")
                }
                .frame(height: 50)
            }
            .padding()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
