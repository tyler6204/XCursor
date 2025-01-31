import * as vscode from 'vscode';
import * as net from 'net';

let client: net.Socket | null = null;
const PORT = 8124;
const HOST = '127.0.0.1';
const RECONNECT_INTERVAL = 5000; // Try reconnecting every 5 seconds

export function activate(context: vscode.ExtensionContext) {
    console.log('🚀 VSCode Extension: Activating...');
    connectToXcodeListener();

    vscode.window.onDidChangeActiveTextEditor(editor => {
        if (editor && editor.document) {
            sendFilePath(editor.document.fileName);
        }
    });

    context.subscriptions.push(
        vscode.workspace.onDidOpenTextDocument(document => sendFilePath(document.fileName)),
        vscode.workspace.onDidSaveTextDocument(document => sendFilePath(document.fileName))
    );
}

function connectToXcodeListener() {
    if (client && !client.destroyed) {
        console.warn("🚨 Already connected. Skipping reconnection attempt.");
        return; // Avoid redundant connections
    }

    client = new net.Socket();

    client.connect(PORT, HOST, () => {
        console.log(`✅ Connected to Xcode Listener on port ${PORT}`);
        return;
    });

    client.on('error', (err) => {
        console.error('❌ VSCode Socket error:', err.message);
        retryConnection();
    });

    client.on('close', (hadError) => {
        console.warn(`🚨 Connection closed${hadError ? ' due to an error' : ''}. Attempting to reconnect...`);
        retryConnection();
    });
}

function retryConnection() {
    if (client && !client.destroyed) {
        console.warn("🚨 Connection retry skipped (socket still active).");
        return; // Prevent unnecessary retries
    }

    setTimeout(() => {
        console.log('🔄 Retrying connection...');
        connectToXcodeListener();
    }, RECONNECT_INTERVAL);
}

function sendFilePath(filePath: string) {
    if (client && client.writable) {
        const message = JSON.stringify({ path: filePath }) + '\n';
        client.write(message, (error) => {
            if (error) {
                console.error('❌ Failed to send file path:', error.message);
            }
        });
    } else {
        console.warn('⚠️ Connection not available. Cannot send file path.');
    }
}

export function deactivate() {
    if (client) {
        client.destroy();
        client = null;
    }
}
