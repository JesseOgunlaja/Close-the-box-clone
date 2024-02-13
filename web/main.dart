import 'dart:html';
import "dart:async";
import 'dart:math';

typedef Div = DivElement;
typedef Image = ImageElement;
typedef Button = ButtonElement;
typedef Dialog = DialogElement;

List<int> usedNumbers = [];
List<int> tempUsedNumbers = [];
List<StreamSubscription> eventListeners = [];
int total = 0;
int totalNeeded = total;
var timer;

enum NumberClickActionType {
  cancel,
  select,
}

final dialogBox = querySelector("dialog") as Dialog;
final diceElement1 = querySelector("#dice-1") as Image;
final diceElement2 = querySelector("#dice-2") as Image;
final playAgainButton = querySelector("#play-again") as Button;
final startGameButton = querySelector("#start-game-button") as Button;
final submitNumbersButton = querySelector("#submit-numbers") as Button;
final cancelNumbersButton = querySelector("#cancel-numbers") as Button;
final diceOptions = querySelector(".dice-options") as Div;
final numbersContainer = querySelector(".numbers-container") as Div;

void main() {
  rollFavicon();
  setupStartGameButton();
  setupPlayAgainButton();
}

void rollFavicon() {
  Timer.periodic(Duration(milliseconds: 200), (timer) {
    final randomNum1 = Random().nextInt(6) + 1;
    final el = querySelector("#icon") as LinkElement;
    el.href = "./assets/dice_$randomNum1.webp";
  });
}

void setupStartGameButton() {
  startGameButton.addEventListener("click", (event) {
    if (startGameButton.text == "Start") {
      rollDice();
      startGameButton.text = "Restart";
    } else {
      disableButtons();
      cancelAllEventListeners();
      resetGame();
      (timer as Timer).cancel();
      startGameButton.text = "Start";
    }
  });
}

void setupPlayAgainButton() {
  playAgainButton.addEventListener("click", (event) {
    resetGame();
    rollDice();
  });
}

void resetGame() {
  diceOptions.style.display = "none";
  diceElement2.style.display = "block";

  for (final numberElement in numbersContainer.children) {
    if (numberElement is Button) {
      numberElement.disabled = false;
      numberElement.style.background = "";
      numberElement.style.transform = "";
    }
  }

  dialogBox.close();
  dialogBox.style.display = "none";

  disableButtons();
  cancelAllEventListeners();

  usedNumbers = [];
  tempUsedNumbers = [];

  diceElement1.src = "./assets/dice_1.webp";
  diceElement2.src = "./assets/dice_1.webp";

  total = 0;
  totalNeeded = total;

  if (timer is Timer) {
    timer.cancel();
  }
}

void rollDice() {
  tempUsedNumbers = [];

  cancelAllEventListeners();
  checkIfWon();
  disableButtons();
  animateDice();

  Future.delayed(Duration(milliseconds: 1600), () {
    if (timer is Timer && timer.isActive) {
      cancelNumbersButton.disabled = false;

      unDisableNumberElements();

      total = getTotalDiceValue();
      totalNeeded = total;

      checkIfLost(total);

      setupCancelNumbers();
      setUpNumberElements();
    }
  });
}

void animateDice() {
  if (timer is Timer) {
    (timer as Timer).cancel();
  }
  timer = Timer.periodic(Duration(milliseconds: 100), (timer) {
    if (usedNumbers.length != 9 && timer.tick < 15) {
      final randomNum1 = Random().nextInt(6) + 1;
      final randomNum2 = Random().nextInt(6) + 1;
      diceElement1.src = "./assets/dice_$randomNum1.webp";
      diceElement2.src = "./assets/dice_$randomNum2.webp";
    }
  });
}

void disableButtons() {
  for (final numbersElement in numbersContainer.children) {
    if (numbersElement is Button) {
      numbersElement.disabled = true;
    }
  }

  cancelNumbersButton.disabled = true;
  submitNumbersButton.disabled = true;
}

void checkIfWon() {
  if (usedNumbers.length == 9) {
    showDialogBox("You won");
  }
}

void checkIfLost(int total) {
  if (usedNumbers.length != 9 &&
      !canMakeSum(
          List<int>.from(numbersContainer.children
              .where((el) => el is Button && el.disabled == false)
              .map((el) {
            return int.parse(el.text!);
          })),
          total)) {
    showDialogBox("You lost");
  }
}

void showDialogBox(String text) {
  Future.delayed(Duration(milliseconds: 300), () {
    dialogBox.children[0].children[0].text = text;
    dialogBox.show();
    dialogBox.style.display = "flex";
    return;
  });
}

void unDisableNumberElements() {
  for (final numberElementEntry in numbersContainer.children.asMap().entries) {
    final numberElement = numberElementEntry.value;
    if (numberElement is Button) {
      if (!usedNumbers.contains(numberElementEntry.key)) {
        numberElement.disabled = false;
        numberElement.style.transform = "";
        numberElement.style.background = "";
      }
    }
  }
}

void handleSubmitNumbers(List<int> tempUsedNumbers) {
  for (final tempUsedNumber in tempUsedNumbers) {
    if (!usedNumbers.contains(tempUsedNumber)) {
      usedNumbers.add(tempUsedNumber);
    }
  }
  for (final usedNumber in usedNumbers) {
    numbersContainer.children[usedNumber].style.background = "#3f3f3f";
    numbersContainer.children[usedNumber].style.transform = "";
  }
  final numbersLeft =
      List<int>.from(numbersContainer.children.whereType<Button>().map((el) {
    return int.parse(el.text!);
  }).where((el) => !usedNumbers.contains(el - 1)));
  if (numbersLeft.isNotEmpty &&
      numbersLeft.indexWhere((element) => element > 6) == -1) {
    handleDiceOptions();
  } else {
    rollDice();
  }
}

void handleDiceOptions() {
  cancelNumbersButton.disabled = true;
  diceOptions.style.display = "flex";
  diceOptions.children[0].onClick.listen((event) {
    diceOptions.style.display = "none";
    final diceElement1Width = diceElement1.getComputedStyle().width;
    for (final diceOption in diceOptions.children) {
      diceOption.style.width = diceElement1Width;
    }
    startGameButton.style.width = diceElement1Width * 2;
    diceElement2.style.display = "none";
    rollDice();
  });
  diceOptions.children[1].onClick.listen((event) {
    diceOptions.style.display = "none";
    diceElement2.style.display = "block";
    rollDice();
  });
}

void numberElementClick(NumberClickActionType clickType, Button numberElement) {
  final elementNumber = int.parse(numberElement.text!);
  switch (clickType) {
    case NumberClickActionType.cancel:
      tempUsedNumbers.remove(elementNumber - 1);
      totalNeeded += elementNumber;
      numberElement.style.transform = "";
      numberElement.style.background = "";
      submitNumbersButton.disabled = true;
      break;
    case NumberClickActionType.select:
      totalNeeded -= elementNumber;
      numberElement.style.background = "#333";
      numberElement.style.transform = "scale(1.055)";
      tempUsedNumbers.add(elementNumber - 1);
  }
}

void setupCancelNumbers() {
  StreamSubscription cancelNumbersSubscription =
      cancelNumbersButton.onClick.listen((event) {
    totalNeeded = total;
    tempUsedNumbers = [];
  });
  eventListeners.add(cancelNumbersSubscription);
}

void setUpNumberElements() {
  for (final numberElement in numbersContainer.children) {
    if (numberElement is Button) {
      StreamSubscription buttonClickSubscription =
          numberElement.onClick.listen((event) {
        if (tempUsedNumbers.contains(int.parse(numberElement.text!) - 1)) {
          numberElementClick(NumberClickActionType.cancel, numberElement);
        } else {
          if (int.parse(numberElement.text!) <= totalNeeded) {
            numberElementClick(NumberClickActionType.select, numberElement);

            if (totalNeeded == 0) {
              handleAbleToSubmit();
            }
          } else {}
        }
      });
      eventListeners.add(buttonClickSubscription);
    }
  }
}

void handleAbleToSubmit() {
  submitNumbersButton.disabled = false;
  StreamSubscription submitButtonClickSubscription =
      submitNumbersButton.onClick.listen((event) {
    handleSubmitNumbers(tempUsedNumbers);
  });
  eventListeners.add(submitButtonClickSubscription);
}

int getTotalDiceValue() {
  final href = window.location.href;

  final useSecondDice = diceElement2.style.display != "none";

  int getDiceValueFromSrc(String src) {
    return int.parse(src.replaceFirst(href, "").substring(12, 13));
  }

  return getDiceValueFromSrc(diceElement1.src!) +
      (useSecondDice == false ? 0 : getDiceValueFromSrc(diceElement2.src!));
}

bool canMakeSum(List<int> numbers, int targetSum) {
  bool canMakeSumRecursive(int index, int currentSum) {
    if (currentSum == targetSum) {
      return true;
    }

    if (index == numbers.length) {
      return false;
    }

    final includeCurrent =
        canMakeSumRecursive(index + 1, currentSum + numbers[index]);

    final excludeCurrent = canMakeSumRecursive(index + 1, currentSum);

    return includeCurrent || excludeCurrent;
  }

  return canMakeSumRecursive(0, 0);
}

void cancelAllEventListeners() {
  for (var subscription in eventListeners) {
    subscription.cancel();
  }
  eventListeners.clear();
}
