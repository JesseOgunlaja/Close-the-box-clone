import 'dart:html';
import "dart:async";
import 'dart:math';

typedef Button = ButtonElement;
typedef Image = ImageElement;
typedef Div = DivElement;

void main() {
  final startGameButton = querySelector("#start-game-button") as Button;
  startGameButton.addEventListener("click", (event) {
    startGameButton.disabled = true;
    rollDice([]);
  });
  final playAgainButton = querySelector("#play-again") as Button;
  playAgainButton.addEventListener("click", (event) {
    final numbersContainer = querySelector(".numbers-container") as Div;
    for (final numberElement in numbersContainer.children) {
      if (numberElement is Button) {
        numberElement.disabled = false;
        numberElement.style.background = "";
        numberElement.style.transform = "";
      }
    }
    final dialogBox = querySelector("dialog") as DialogElement;
    dialogBox.close();
    dialogBox.style.display = "none";

    // Cancel all event listeners
    cancelAllEventListeners();

    rollDice([]);
  });
}

// List to store StreamSubscriptions
List<StreamSubscription> eventListeners = [];

void rollDice(List<int> usedNumbers) {
  final diceElemenet1 = querySelector("#dice-1") as Image;
  final diceElemenet2 = querySelector("#dice-2") as Image;
  final numbersContainer = querySelector(".numbers-container") as Div;
  final submitNumbersButton = querySelector("#submit-numbers") as Button;
  final cancelNumbersButton = querySelector("#cancel-numbers") as Button;

  if (usedNumbers.length == 9) {
    Future.delayed(Duration(milliseconds: 500), () {
      final dialogBox = querySelector("dialog") as DialogElement;
      dialogBox.firstChild!.firstChild!.text = "You won";
      dialogBox.show();
      dialogBox.style.display = "flex";
      return;
    });
    return;
  }

  for (final usedNumber in usedNumbers) {
    numbersContainer.children[usedNumber].style.background = "#3f3f3f";
    numbersContainer.children[usedNumber].style.transform = "";
  }

  for (final numbersElement in numbersContainer.children) {
    if (numbersElement is Button) {
      numbersElement.disabled = true;
    }
  }

  cancelNumbersButton.disabled = true;
  submitNumbersButton.disabled = true;

  Timer.periodic(Duration(milliseconds: 100), (timer) {
    final randomNum1 = Random().nextInt(6) + 1;
    final randomNum2 = Random().nextInt(6) + 1;
    diceElemenet1.src = "./assets/dice_$randomNum1.png";
    diceElemenet2.src = "./assets/dice_$randomNum2.png";
    if (timer.tick == 15) {
      timer.cancel();
    }
  });

  Future.delayed(Duration(milliseconds: 1600), () {
    List<int> tempUsedNumbers = [];
    cancelNumbersButton.disabled = false;

    for (final numbersElement in numbersContainer.children.asMap().entries) {
      if (numbersElement.value is Button &&
          !usedNumbers.contains(numbersElement.key)) {
        (numbersElement.value as Button).disabled = false;
      }
    }

    final total = getTotalDiceValue();

    if (!canMakeSum(
        List<int>.from(numbersContainer.children
            .whereType<Button>()
            .where((el) => el.disabled == false)
            .map((el) {
          return int.parse(el.text!);
        })),
        total)) {
      Future.delayed(Duration(milliseconds: 500), () {
        final dialogBox = querySelector("dialog") as DialogElement;
        dialogBox.children[0].children[0].text = "You lost";
        dialogBox.show();
        dialogBox.style.display = "flex";
        return;
      });
      return;
    }

    var totalNeeded = total;
    StreamSubscription cancelNumbersSubscription;
    cancelNumbersSubscription = cancelNumbersButton.onClick.listen((event) {
      totalNeeded = total;
      tempUsedNumbers = [];
      for (final numberElement in numbersContainer.children) {
        if (numberElement.style.background == "rgb(51, 51, 51)") {
          numberElement.style.transform = "";
          numberElement.style.background = "";
          (numberElement as Button).disabled = false;
        }
      }
    });
    eventListeners.add(cancelNumbersSubscription);

    for (final numberElement in numbersContainer.children) {
      if (numberElement is Button) {
        final elementNumber = int.parse(numberElement.text!);
        StreamSubscription buttonClickSubscription;
        buttonClickSubscription = numberElement.onClick.listen((event) {
          if (totalNeeded > 0) {
            if (tempUsedNumbers.contains(elementNumber - 1)) {
              totalNeeded += elementNumber;
              tempUsedNumbers.remove(elementNumber - 1);
              numberElement.style.transform = "";
              numberElement.style.background = "";
              submitNumbersButton.disabled = true;
            } else {
              if (int.parse(numberElement.text!) <= totalNeeded) {
                totalNeeded -= elementNumber;
                numberElement.style.background = "#333";
                numberElement.style.transform = "scale(1.055)";
                tempUsedNumbers.add(elementNumber - 1);

                if (totalNeeded == 0) {
                  submitNumbersButton.disabled = false;
                  StreamSubscription submitButtonClickSubscription;
                  submitButtonClickSubscription =
                      submitNumbersButton.onClick.listen((event) {
                    for (final tempUsedNumber in tempUsedNumbers) {
                      if (!usedNumbers.contains(tempUsedNumber)) {
                        usedNumbers.add(tempUsedNumber);
                      }
                    }
                    if (usedNumbers.length != 9) {
                      rollDice(usedNumbers);
                    }
                  });
                  eventListeners.add(submitButtonClickSubscription);
                }
              }
            }
          }
        });
        eventListeners.add(buttonClickSubscription);
      }
    }
  });
}

int getTotalDiceValue() {
  final diceElemenet1 = querySelector("#dice-1") as Image;
  final diceElemenet2 = querySelector("#dice-2") as Image;
  final href = window.location.href;

  int getDiceValueFromSrc(String src) {
    return int.parse(src.replaceFirst(href, "").substring(12, 13));
  }

  return getDiceValueFromSrc(diceElemenet1.src!) +
      getDiceValueFromSrc(diceElemenet2.src!);
}

bool canMakeSum(List<int> numbers, int targetSum) {
  dynamic canMakeSumRecursive(int index, int currentSum) {
    if (currentSum == targetSum) {
      return true;
    }

    if (index == numbers.length) {
      return false;
    }

    // Include the current number in the sum
    final includeCurrent =
        canMakeSumRecursive(index + 1, currentSum + numbers[index]);

    // Exclude the current number from the sum
    final excludeCurrent = canMakeSumRecursive(index + 1, currentSum);

    return includeCurrent || excludeCurrent;
  }

  return canMakeSumRecursive(0, 0);
}

// Function to cancel all event listeners
void cancelAllEventListeners() {
  for (var subscription in eventListeners) {
    subscription.cancel();
  }
  eventListeners.clear();
}
