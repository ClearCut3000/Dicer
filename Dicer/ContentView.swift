//
//  ContentView.swift
//  Dicer
//
//  Created by Николай Никитин on 17.11.2022.
//

import SwiftUI

struct ContentView: View {

  //MARK: - View Properties
  var diceTypes = [4, 6, 8, 10, 12, 20, 100]

  @Environment(\.accessibilityVoiceOverEnabled) var voiceOverEnabled
  @AppStorage("selectedDiceType") var selectedDiceType = 6
  @AppStorage("numberToRoll") var numberToRoll = 4

  @State private var currentResult = DiceResult(type: 0, number: 0)

  let timer = Timer.publish(every: 0.1,
                            tolerance: 0.1,
                            on: .main,
                            in: .common).autoconnect()
  @State private var stoppedDice = 0

  @State private var feedback = UIImpactFeedbackGenerator(style: .rigid)

  let savePath = FileManager.documentsDirectory.appendingPathExtension("SavedRollas.json")
  @State private var savedResults = [DiceResult]()

  let columns: [GridItem] = [
    .init(.adaptive(minimum: 60))
  ]

  //MARK: - View Body
    var body: some View {
      NavigationView {
        Form {
          Section {
            Picker("Type of Dice", selection: $selectedDiceType) {
              ForEach(diceTypes, id: \.self) { type in
                Text("D\(type)")
              }
            }
            .pickerStyle(.segmented)
            Stepper("Number of Dice: \(numberToRoll)", value: $numberToRoll, in: 1...20)
            Button("Roll Them!", action: rollDice)
          } footer: {
            LazyVGrid(columns: columns) {
              ForEach(0..<currentResult.rolls.count, id: \.self) { rollNumber in
                Text(String(currentResult.rolls[rollNumber]))
                  .frame(maxWidth: .infinity, maxHeight: .infinity)
                  .aspectRatio(1, contentMode: .fit)
                  .foregroundColor(.black)
                  .background(.white)
                  .cornerRadius(10)
                  .shadow(radius: 3)
                  .font(.title)
                  .padding(5)
              }
            }
            .accessibilityElement()
            .accessibilityLabel("Latest roll: \(currentResult.description)")
          }
          .disabled(stoppedDice < currentResult.rolls.count)
          if savedResults.isEmpty == false {
            Section("Previous results") {
              ForEach(savedResults) { result in
                VStack(alignment: .leading) {
                  Text("\(result.number) * D\(result.type)")
                    .font(.headline)
                  Text(result.description)
                }
                .accessibilityElement()
                .accessibilityLabel("\(result.number) D\(result.type), \(result.description)")
              }
            }
          }
        }
        .navigationTitle("Dicer")
        .onReceive(timer) { date in
          updateDice()
        }
        .onAppear(perform: load)
      }
    }

  //MARK: - View Methods
  func rollDice() {
    currentResult = DiceResult(type: selectedDiceType, number: numberToRoll)

    if voiceOverEnabled {
      stoppedDice = numberToRoll
      savedResults.insert(currentResult, at: 0)
      save()
    } else {
      stoppedDice = -20
    }

    stoppedDice = 0
  }

  func updateDice() {
    guard stoppedDice < currentResult.rolls.count else { return }
    for i in stoppedDice..<numberToRoll {
      if i < 0 { continue }
      currentResult.rolls[i] = Int.random(in: 1...selectedDiceType)
      feedback.impactOccurred()
    }
    stoppedDice += 1
    if stoppedDice == numberToRoll {
      savedResults.insert(currentResult, at: 0)
      save()
    }
  }

  func load() {
    if let data = try? Data(contentsOf: savePath) {
      if let results = try? JSONDecoder().decode([DiceResult].self, from: data) {
        savedResults = results
      }
    }
  }

  func save() {
    if let data = try? JSONEncoder().encode(savedResults) {
      try? data.write(to: savePath, options: [.atomic, .completeFileProtection])
    }
  }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
