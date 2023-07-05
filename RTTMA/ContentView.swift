//
//  ContentView.swift
//  RTTMA
//
//  Created by Quisette Chung on 2023/7/5.
//


import SwiftUI
import SocketIO

// extension for quicker string formatting
extension Double{
    var shortDisplay: String{
        return String(format: "%.4f", self)
    }
}

struct ContentView: View {
    @State private var socket: SocketIOClient!
    let manager = SocketManager(socketURL: URL(string: "http://snmg-gs.ce.ncu.edu.tw:35000")! )
//    let manager = SocketManager(socketURL: URL(string: "http://192.168.0.219:5000")! ,config: [.log(true), .compress]) // local network test
    
    // state variables
    @State private var userid = ""
    @State private var reportplate = ""
    @State private var lat = 123.0
    @State private var lon = 456.0
    @State private var usertext = "Send UserID"
    @State private var reporttext = "Send Plate Number"
    @State private var notificationtext = ""
    
    // timer to update user's location per sec
    let timer = Timer.publish(every: 1,  on: .main , in: .common)
    
    // struct for a car
    struct danger_car {
        let lat: Double
        let lon: Double
        let plate: String
        init(json: [String: Any]){
            self.lat = json["lat"] as? Double ?? 0.0
            self.lon = json["lon"] as? Double ?? 0.0
            self.plate = json["plate"] as? String ?? ""
            
        }
    }
    
    // main body view
    var body: some View {
        VStack {
            Text("Traffic Danger Report System by MWNL").font(.title)
            Text(notificationtext).bold()
            HStack{
                Text("Latitude:\(lat.shortDisplay) ").padding()
                Text("Longitude:\(lon.shortDisplay)").padding()
            }.padding()
                // trigger function for timer
                .onReceive(self.timer, perform: { _ in
                lat += 0.0001
                lon += 0.0001
                    if userid != ""{
                        self.socket.emit("user-update", ["userId": userid, "lat": lat, "lon": lon])
                    }
                
                })
            TextField("User ID", text: $userid)
                .padding()
            Button(action: {
                // start the timer and send connect signal
                
                timer.connect()
                self.socket.emit("user-connect", ["userId": userid, "lat": lat, "lon": lon])
            })
            {
                Text(usertext)
            }
            TextField("plate to report", text: $reportplate)
                .padding()
            Button(action: {
                // plate report
                self.socket.emit("user-report", ["userId": userid, "lat": lat, "lon" : lon, "plates": [reportplate]])
            }) {
                Text(reporttext)
            }
        }
        .onAppear {
            // view init function
            self.socket  = manager.defaultSocket
            self.socket.connect()
            self.setUpSocketEvents()
            
        }
    }
    func setUpSocketEvents(){
        // listening all events
        socket?.on("user-connect-ok"){_,_ in
            usertext = "Device ID: \(userid). Got it!"
        }
        socket?.on("user-report-ack"){_,_ in
            reporttext = "Car \(reportplate) reported. Be Safe!"
            
        }
        socket?.on("accident") {
            _, _ in
            notificationtext = "An accident happened ahead. Drive carefully. "
        }
        socket?.on("danger-alert"){
            data, ack in
            let car = danger_car(json: data[0] as! [String :Any])
            notificationtext = "Danger alert: \(car.plate)  at \n \(car.lat.shortDisplay),\(car.lon.shortDisplay)"
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 3) {
              notificationtext = ""
            }
        }
        
    }
    
    
}


//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}

//#Preview {
//    ContentView()
//}
