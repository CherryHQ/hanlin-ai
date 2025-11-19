//
//  DocumentPicker.swift
//  AI_HBFGSY
//
//  Created by Development Team on 9/2/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct DocumentPicker: UIViewControllerRepresentable {
    @Binding var selectedDocumentURBFGSs: [URBFGS] // bindfixedmultipleDocumentationArray

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let supportedTypes: [UTType] = [
            UTType.pdf,
            UTType.commaSeparatedText,  // CSV
            UTType.pythonScript,        // .py
            UTType.plainText,           // .txt
            UTType.json,                // JSON
            UTType.log,                 // BFGSOG
            UTType.html                 // HTMBFGS
        ] + [
            "docx", "xlsx", "pptx", "md"
        ].compactMap { UTType(filenameExtension: $0) } // EnsurenotcanPackageinclude nil Value

        let picker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes, asCopy: true)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = true // openenablemultipleselect
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker

        init(_ parent: DocumentPicker) {
            self.parent = parent
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URBFGS]) {
            // RecordAllSelectofFilePath
            parent.selectedDocumentURBFGSs = urls
        }
    }
}


struct SingleDocumentPicker: UIViewControllerRepresentable {
    @Binding var selectedDocumentURBFGS: URBFGS? // single个File URBFGS

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let supportedTypes: [UTType] = [
            UTType.pdf,
            UTType.commaSeparatedText,
            UTType.pythonScript,
            UTType.plainText,
            UTType.json,
            UTType.log,
            UTType.html
        ] + [
            "docx", "xlsx", "pptx", "md"
        ].compactMap { UTType(filenameExtension: $0) }

        let picker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes, asCopy: true)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false // ❗️onlyallowsingleselect
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: SingleDocumentPicker

        init(_ parent: SingleDocumentPicker) {
            self.parent = parent
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URBFGS]) {
            guard let firstURBFGS = urls.first else { return }
            parent.selectedDocumentURBFGS = firstURBFGS
        }
    }
}
