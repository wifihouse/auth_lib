// @dart=2.9
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

const BACKGROUND_2 = const Color(0XFF2E3840);
const FC = const Color(0XFF67A1F3);
const WHITE = const Color(0xFFFFFFFF);

class CodeInputDialog extends StatefulWidget {
  final String title;
  final String phone;
  final Function(String) confirmCodePressed;
  final Function cancelPressed;
  final Function resendPressed;

  CodeInputDialog(
      {this.title,
      this.phone,
      this.confirmCodePressed,
      this.cancelPressed,
      this.resendPressed});

  @override
  State<StatefulWidget> createState() {
    return _CodeInputDialogState();
  }
}

class _CodeInputDialogState extends State<CodeInputDialog> {
  TextEditingController textEditingController = TextEditingController();
  // ..text = "123456";

  // ignore: close_sinks
  StreamController<ErrorAnimationType> errorController =
      StreamController<ErrorAnimationType>();

  RxBool hasError = false.obs;
  RxString currentText = "".obs;
  final formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    textEditingController.dispose();
    errorController.close();
    super.dispose();
  }

  Widget contentRender() {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: RichText(
              text: TextSpan(
                  text: "We have sent a 6-digit OTP on mobile number: ",
                  children: [
                    TextSpan(
                        text: widget.phone,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontWeight: FontWeight.bold,
                            height: 1,
                            fontSize: 15)),
                  ],
                  style: TextStyle(color: Colors.white, fontSize: 15)),
              textAlign: TextAlign.start,
            ),
          ),
          SizedBox(
            height: 20,
          ),
          Form(
              key: formKey,
              child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 5.0, horizontal: 5),
                  child: PinCodeTextField(
                    appContext: context,
                    pastedTextStyle: TextStyle(
                      color: WHITE,
                      fontWeight: FontWeight.bold,
                    ),
                    length: 6,
                    blinkWhenObscuring: true,
                    animationType: AnimationType.fade,
                    validator: (v) {
                      return null;
                    },
                    pinTheme: PinTheme(
                        shape: PinCodeFieldShape.box,
                        borderRadius: BorderRadius.circular(10),
                        fieldHeight: 40,
                        fieldWidth: 40,
                        activeFillColor: WHITE,
                        activeColor: WHITE,
                        selectedColor: Colors.grey,
                        disabledColor: Colors.grey,
                        borderWidth: 1,
                        inactiveFillColor: WHITE,
                        inactiveColor: Colors.grey.withOpacity(0.5),
                        selectedFillColor: WHITE),
                    cursorColor: Colors.black,
                    animationDuration: Duration(milliseconds: 300),
                    enableActiveFill: true,
                    errorAnimationController: errorController,
                    controller: textEditingController,
                    keyboardType: TextInputType.number,
                    textStyle: TextStyle(color: BACKGROUND_2),
                    boxShadows: [
                      BoxShadow(
                        offset: Offset(0, 1),
                        color: Colors.black12,
                        blurRadius: 10,
                      )
                    ],
                    onCompleted: (v) {
                      formKey.currentState.validate();
                      if (currentText.value.length != 6) {
                        errorController.add(ErrorAnimationType.shake);
                      } else {
                        hasError.value = false;
                        widget.confirmCodePressed(v);
                      }
                    },
                    onChanged: (value) {
                      currentText.value = value;
                    },
                    beforeTextPaste: (text) {
                      print("Allowing to paste $text");
                      //if you return true then it will show the paste confirmation dialog. Otherwise if false, then nothing will happen.
                      //but you can show anything you want here, like your pop up saying wrong paste format or etc
                      return true;
                    },
                  ))),

          GestureDetector(
            onTap: widget.resendPressed,
            child: Container(
                alignment: Alignment.center,
                padding: EdgeInsets.only(bottom: 10),
                child: Text("Resend OTP",
                    style: TextStyle(
                        color: FC, fontSize: 14, fontWeight: FontWeight.w900))),
          )

          // Row(
          //   mainAxisAlignment: MainAxisAlignment.center,
          //   children: [
          //     Text(
          //       "I don’t recevie a code!",
          //       style: TextStyle(color: Colors.black54, fontSize: 15),
          //     ),
          //     TextButton(
          //         onPressed: () {
          //            widget.onResend();
          //         },
          //         child: Text(
          //           "Please resend",
          //           style: TextStyle(
          //               color: BACKGROUND_2,
          //               fontWeight: FontWeight.bold,
          //               fontSize: 16),
          //         ))
          //   ],
          // ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
        backgroundColor: BACKGROUND_2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          decoration: BoxDecoration(
            color: BACKGROUND_2,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        widget.title != null
                            ? Text(widget.title,
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white))
                            : Container(),
                        IconButton(
                          onPressed: () {
                            widget.cancelPressed();
                            // Get.back();
                          },
                          icon: Icon(Icons.clear_outlined, color: Colors.white),
                        )
                      ])),
              Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: contentRender()),
            ],
          ),
        ));
    // return Dialog(
    //     backgroundColor: Colors.white,
    //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    //     child: Container(
    //       child: Column(
    //         crossAxisAlignment: CrossAxisAlignment.center,
    //         mainAxisSize: MainAxisSize.min,
    //         children: [
    //           Text("Plz input code bellow"),
    //           TextField(
    //             controller: _codeController,
    //             keyboardType: TextInputType.number,
    //           ),
    //           Row(
    //             children: [
    //               TextButton(
    //                   onPressed: () => widget.cancelPressed(),
    //                   child: Text("CANCEL")),
    //               TextButton(
    //                   onPressed: () =>
    //                       widget.confirmCodePressed(_codeController.value.text),
    //                   child: Text("CONFIRM"))
    //             ],
    //           )
    //         ],
    //       ),
    //     ));
  }
}

// Entry point
// void recordDialog(BuildContext context,
//     {RecordType type,
//     String fileName,
//     String furiganaText,
//     Function onCancel,
//     Function onStart,
//     Function onPlayNow,
//     Function onDone,
//     Function onRecordAgain,
//     Function(MatchingResult) onTestResult}) {
//   showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (BuildContext context) {
//         return CodeInputDialog();
//       });
// }
