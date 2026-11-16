/// Gives a dialog route time to finish its exit transition before the caller
/// updates the page tree, navigates, or disposes controllers used by it.
Future<void> waitForDialogDismissal() =>
    Future<void>.delayed(const Duration(milliseconds: 200));
