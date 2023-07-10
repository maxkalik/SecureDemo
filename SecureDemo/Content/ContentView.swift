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
                
                if viewModel.isLoadingButton1 {
                    ProgressView()
                        .frame(height: 50)
                } else {
                    Button {
                        viewModel.buttonOnePressed()
                    } label: {
                        Text("Start Request 1")
                    }
                    .frame(height: 50)
                }
                
                if viewModel.isLoadingButton2 {
                    ProgressView()
                        .frame(height: 50)
                } else {
                    Button {
                        viewModel.buttonTwoPressed()
                    } label: {
                        Text("Start Request 2")
                    }
                    .frame(height: 50)
                }
                
                if viewModel.isLoadingButton3 {
                    ProgressView()
                        .frame(height: 50)
                } else {
                    Button {
                        viewModel.buttonThreePressed()
                    } label: {
                        Text("Start Request 3")
                    }
                    .frame(height: 50)
                }
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
