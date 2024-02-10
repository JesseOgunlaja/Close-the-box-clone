@TestOn("browser")
import 'dart:async';
import 'dart:html';
import 'package:test/test.dart';
import '../web/main.dart';

typedef Button = ButtonElement;
typedef Image = ImageElement;
typedef Div = DivElement;

int diceTotal = 9;

void main() {
  final startGameButton = querySelector("#start-game-button") as Button;
  final submitNumbersButton = querySelector("#submit-numbers") as Button;
  final playAgainButton = querySelector("#play-again") as Button;
  final numbersContainer = querySelector(".numbers-container") as Div;
  final diceOptions = querySelector(".dice-options") as Div;

  clickNumberElemenet(int index, [bool clickDiceOption = true]) {
    numbersContainer.children[index - 1].click();
    if (submitNumbersButton.disabled == false) {
      submitNumbersButton.click();
      if (clickDiceOption) {
        diceOptions.children[1].click();
      }
    }
    return Future.delayed(Duration(microseconds: 1));
  }

  clickNumberElemenets([String losingOrWinning = "Losing"]) async {
    await Future.delayed(Duration(microseconds: 1));

    await clickNumberElemenet(9);

    clickNumberElemenet(8);
    await clickNumberElemenet(1);

    clickNumberElemenet(7);
    await clickNumberElemenet(2);

    clickNumberElemenet(6);
    if (losingOrWinning == "Winning") {
      await clickNumberElemenet(3);
    } else {
      clickNumberElemenet(3);
    }
  }

  test("Test winning", () async {
    startGame(returnDiceValue, true);

    startGameButton.click();

    await clickNumberElemenets("Winning");

    clickNumberElemenet(5);
    await clickNumberElemenet(4, false);

    final dialogBox = querySelector("dialog") as DialogElement;
    expect(dialogBox.children[0].children[0].text, equals("You wonn"));
  });

  test("Test losing", () async {
    playAgainButton.click();

    await clickNumberElemenets();

    diceTotal = 10;

    await Future.delayed(Duration(milliseconds: 10));

    final dialogBox = querySelector("dialog") as DialogElement;
    expect(dialogBox.children[0].children[0].text, equals("You lost"));
  });
}

int returnDiceValue() {
  return diceTotal;
}
