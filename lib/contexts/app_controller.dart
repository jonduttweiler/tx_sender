import 'dart:async';

import 'package:flutter/material.dart';
import 'package:reown_appkit/reown_appkit.dart';
import 'package:tx_sender/constants.dart';
import 'package:tx_sender/erc20abi.dart';

final ReownAppKitModalNetworkInfo celoMainnet = ReownAppKitModalNetworkInfo(
  name: "Celo Mainnet",
  chainId: '42220',
  chainIcon: 'ab781bbc-ccc6-418d-d32d-789b15da1f00',
  currency: 'CELO',
  rpcUrl: "https://forno.celo.org/",
  explorerUrl: "https://celoscan.io",
);

class AppController extends ChangeNotifier {
  bool modalInitialized = false;
  bool initializingModal = false;
  String account = "";
  bool isConnected = false;

  ReownAppKit? appKit;
  late ReownAppKitModal _appKitModal;
  ReownAppKitModal get appKitModal => _appKitModal;

  final Set<String> includedWalletIds = {
    'c57ca95b47569778a828d19178114f4db188b89b763c899ba0be274e97267d96', // MetaMask
    'd01c7758d741b363e637a817a09bcf579feae4db9f5bb16f599fdd1f66e2f974', // Valora
    'fd20dc426fb37566d803205b19bbc1d4096b248ac04548e3cfb6b3a38bd033aa', // Coinbase Wallet
    '4622a2b2d6af1c9844944291e5e7351a6aa24cd7b23099efac1b2fd875da31a0', // Trust
  };

  final Map<String, RequiredNamespace> requiredNamespaces = {
    'eip155': RequiredNamespace(
      chains: ["eip155:42220"],
      methods: ["personal_sign", "eth_sendTransaction", "eth_requestAccounts"],
      events: ["chainChanged", "accountsChanged"],
    ),
  };

  Future<void> initialize() async {
    appKit = await ReownAppKit.createInstance(
      projectId: projectId,
      metadata: const PairingMetadata(
        name: 'Forest Maker App',
        description: 'ForestMaker',
        url: 'https://forestmaker.org',
        icons: ['https://explorer.forestmaker.org/logo.png'],
        redirect: Redirect(native: 'flutterdapp://', universal: 'https://www.walletconnect.com'),
      ),
    );
    print("Web3 app and service initialized");
  }

  Future<ReownAppKitModal?> initializeModal(BuildContext context) async {
    Stopwatch stopwatch = Stopwatch()..start();

    if (appKit == null) {
      await initialize();
    }

    if (modalInitialized) {
      return _appKitModal;
    }

    if (initializingModal) return null;

    initializingModal = true;
    notifyListeners();

    try {
      _appKitModal = ReownAppKitModal(
        context: context,
        appKit: appKit,
        includedWalletIds: includedWalletIds,
        requiredNamespaces: requiredNamespaces,
      );

      await _appKitModal.init();
      await _appKitModal.selectChain(celoMainnet);
      modalInitialized = true;

      if (_appKitModal.isConnected) {
        final address = _appKitModal.session?.getAddress("eip155");
        if (address != null && address.isNotEmpty) {
          account = address;
        }
      }

      print('Initialize modal time elapsed: ${stopwatch.elapsedMilliseconds} ms');
      stopwatch.reset();
      initializingModal = false;
      return _appKitModal;
    } catch (err, stack) {
      initializingModal = false;
      rethrow;
    }
  }

  Future<String?> connectWallet(BuildContext context) async {
    if (!modalInitialized) {
      await initializeModal(context);
    }

    if (_appKitModal.isConnected) {
      final address = _appKitModal.session?.getAddress("eip155");
      if (address != null) {
        account = address;
        notifyListeners();
      }
      return address;
    }

    return await establishWalletConnection();
  }

  Future<String?> establishWalletConnection() async {
    final completer = Completer<String?>();

    void onError(ModalError? event) {
      print(event);
      completer.completeError("Connection failed");
    }

    void onConnection(ModalConnect? event) {
      if (event?.session.getAddress("eip155") != null) {
        account = event!.session.getAddress("eip155")!;
        isConnected = true;

        if (!completer.isCompleted) {
          completer.complete(account);
        }
        appKitModal.onModalConnect.unsubscribe(onConnection);
        appKitModal.onModalError.unsubscribe(onError);
      }
    }

    appKitModal.onModalConnect.subscribe(onConnection);
    appKitModal.onModalError.subscribe(onError);

    await appKitModal.openModalView();

    return completer.future;
  }

  sendReadTransaction() async {
    final usdcAddress = EthereumAddress.fromHex("0xcebA9300f2b948710d2653dD7B07f33A8B32118C");
    final DeployedContract contract = DeployedContract(erc20Abi, usdcAddress);

    if (account.isEmpty) {
      throw Exception("No account detected");
    }
    var result = await appKitModal.requestReadContract(
      chainId: "eip155:42220",
      topic: appKitModal.session!.topic,
      deployedContract: contract,
      functionName: "balanceOf",
      parameters: [EthereumAddress.fromHex(account)],
    );

    final balance = result[0] as BigInt;
    return balance / BigInt.from(10).pow(6);
  }

  sendWriteTransaction() async {
    //Invoke an approve function over USCDC smart contract
    final usdcAddress = EthereumAddress.fromHex("0xcebA9300f2b948710d2653dD7B07f33A8B32118C");
    final DeployedContract contract = DeployedContract(erc20Abi, usdcAddress);

    final spender = EthereumAddress.fromHex("0xC3E5e496c0443C4C95F4a6f087F97c9FFC377379");

    if (account.isEmpty) {
      throw Exception("No account detected");
    }
    var txHash = await appKitModal.requestWriteContract(
      chainId: "eip155:42220",
      topic: appKitModal.session!.topic,
      deployedContract: contract,
      functionName: "approve",
      transaction: Transaction(from: EthereumAddress.fromHex(account)),
      parameters: [spender, BigInt.from(1)],
    );

    print(txHash);
  }
}
