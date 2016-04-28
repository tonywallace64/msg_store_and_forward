Mailbox

Implement a store and forward messaging system.

Before mail can be sent to a recipient, it must be registered.  When registered it has a mailbox.  A mailbox is a file that can store messages to that address.  When messages arrive they are appended to the mailbox file.  When a getmail message is received, the contents of that file are passed onto the recipient and the mailbox is emptied.