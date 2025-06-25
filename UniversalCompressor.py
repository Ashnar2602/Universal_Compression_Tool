#!/usr/bin/env python3
"""
Universal ISO Compression Tool
Python implementation of the AutoHotkey version
"""

import tkinter as tk
from tkinter import ttk, filedialog, messagebox
import subprocess
import os
import threading
import time
from pathlib import Path
import configparser

class UniversalCompressor:
    def __init__(self):
        self.root = tk.Tk()
        self.root.title("Universal ISO Compression Tool v1.0.0")
        self.root.geometry("800x600")
        self.root.resizable(True, True)
        
        # Configuration
        self.config = configparser.ConfigParser()
        self.config_file = "settings.ini"
        self.load_settings()
        
        # Variables
        self.compression_type = tk.StringVar(value="CSO")
        self.output_folder = tk.StringVar(value=os.path.expanduser("~/Desktop"))
        self.force_overwrite = tk.BooleanVar(value=True)
        self.delete_input = tk.BooleanVar(value=False)
        
        # File list
        self.file_list = []
        
        # Check executables
        self.check_executables()
        
        # Create GUI
        self.create_gui()
        
    def check_executables(self):
        """Check if required executables exist"""
        missing = []
        
        if not os.path.exists("maxcso.exe"):
            missing.append("maxcso.exe (for CSO compression)")
            
        if not os.path.exists("chdman.exe"):
            missing.append("chdman.exe (for CHD compression)")
            
        if missing:
            messagebox.showerror(
                "Missing Executables",
                f"The following required files are missing:\n\n" +
                "\n".join(f"• {item}" for item in missing) +
                "\n\nPlease place these files in the same directory as this application."
            )
            self.root.quit()
    
    def create_gui(self):
        """Create the main GUI"""
        # Main frame
        main_frame = ttk.Frame(self.root, padding="20")
        main_frame.grid(row=0, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))
        
        # Configure grid weights
        self.root.columnconfigure(0, weight=1)
        self.root.rowconfigure(0, weight=1)
        main_frame.columnconfigure(1, weight=1)
        
        # Title
        title_label = ttk.Label(main_frame, text="Universal ISO Compression Tool", 
                               font=("Arial", 16, "bold"))
        title_label.grid(row=0, column=0, columnspan=3, pady=(0, 10))
        
        subtitle_label = ttk.Label(main_frame, text="Compress ISO files to CHD or CSO format")
        subtitle_label.grid(row=1, column=0, columnspan=3, pady=(0, 20))
        
        # Compression type selection
        comp_frame = ttk.LabelFrame(main_frame, text="Compression Type", padding="10")
        comp_frame.grid(row=2, column=0, columnspan=3, sticky=(tk.W, tk.E), pady=(0, 10))
        
        ttk.Radiobutton(comp_frame, text="CSO Format", variable=self.compression_type, 
                       value="CSO", command=self.update_description).grid(row=0, column=0, sticky=tk.W)
        ttk.Radiobutton(comp_frame, text="CHD Format", variable=self.compression_type, 
                       value="CHD", command=self.update_description).grid(row=0, column=1, sticky=tk.W)
        
        self.desc_label = ttk.Label(comp_frame, text="", wraplength=600)
        self.desc_label.grid(row=1, column=0, columnspan=2, sticky=(tk.W, tk.E), pady=(10, 0))
        self.update_description()
        
        # File selection
        file_frame = ttk.LabelFrame(main_frame, text="Input Files", padding="10")
        file_frame.grid(row=3, column=0, columnspan=3, sticky=(tk.W, tk.E, tk.N, tk.S), pady=(0, 10))
        file_frame.columnconfigure(1, weight=1)
        file_frame.rowconfigure(1, weight=1)
        
        ttk.Button(file_frame, text="Select ISO Files", 
                  command=self.select_files).grid(row=0, column=0, padx=(0, 10))
        ttk.Button(file_frame, text="Clear All", 
                  command=self.clear_files).grid(row=0, column=1, sticky=tk.W)
        
        # File list
        self.tree = ttk.Treeview(file_frame, columns=("Size", "Status"), show="tree headings")
        self.tree.heading("#0", text="File")
        self.tree.heading("Size", text="Size")
        self.tree.heading("Status", text="Status")
        self.tree.column("#0", width=400)
        self.tree.column("Size", width=100)
        self.tree.column("Status", width=100)
        self.tree.grid(row=1, column=0, columnspan=2, sticky=(tk.W, tk.E, tk.N, tk.S), pady=(10, 0))
        
        # Scrollbar for file list
        scrollbar = ttk.Scrollbar(file_frame, orient="vertical", command=self.tree.yview)
        scrollbar.grid(row=1, column=2, sticky=(tk.N, tk.S))
        self.tree.configure(yscrollcommand=scrollbar.set)
        
        # Output folder
        output_frame = ttk.LabelFrame(main_frame, text="Output Folder", padding="10")
        output_frame.grid(row=4, column=0, columnspan=3, sticky=(tk.W, tk.E), pady=(0, 10))
        output_frame.columnconfigure(0, weight=1)
        
        ttk.Entry(output_frame, textvariable=self.output_folder, state="readonly").grid(
            row=0, column=0, sticky=(tk.W, tk.E), padx=(0, 10))
        ttk.Button(output_frame, text="Browse", 
                  command=self.select_output_folder).grid(row=0, column=1)
        
        # Options
        options_frame = ttk.LabelFrame(main_frame, text="Options", padding="10")
        options_frame.grid(row=5, column=0, columnspan=3, sticky=(tk.W, tk.E), pady=(0, 10))
        
        ttk.Checkbutton(options_frame, text="Force overwrite existing files", 
                       variable=self.force_overwrite).grid(row=0, column=0, sticky=tk.W)
        ttk.Checkbutton(options_frame, text="Delete input files after success", 
                       variable=self.delete_input).grid(row=0, column=1, sticky=tk.W)
        
        # Control buttons
        button_frame = ttk.Frame(main_frame)
        button_frame.grid(row=6, column=0, columnspan=3, pady=(10, 0))
        
        self.start_button = ttk.Button(button_frame, text="Start Compression", 
                                      command=self.start_compression)
        self.start_button.grid(row=0, column=0, padx=(0, 10))
        
        self.stop_button = ttk.Button(button_frame, text="Stop", 
                                     command=self.stop_compression, state="disabled")
        self.stop_button.grid(row=0, column=1)
        
        # Status bar
        self.status_var = tk.StringVar(value="Ready")
        status_bar = ttk.Label(main_frame, textvariable=self.status_var, relief=tk.SUNKEN)
        status_bar.grid(row=7, column=0, columnspan=3, sticky=(tk.W, tk.E), pady=(10, 0))
        
        # Progress bar
        self.progress = ttk.Progressbar(main_frame, mode='determinate')
        self.progress.grid(row=8, column=0, columnspan=3, sticky=(tk.W, tk.E), pady=(5, 0))
    
    def update_description(self):
        """Update compression type description"""
        if self.compression_type.get() == "CSO":
            desc = "CSO (Compressed ISO): PlayStation Portable compressed format for PSP and PS2 emulators. Provides good compression ratios with fast decompression."
        else:
            desc = "CHD (Compressed Hunks of Data): MAME compressed format for hard disk images. Excellent compression for arcade and computer system ROMs."
        
        self.desc_label.config(text=desc)
    
    def select_files(self):
        """Select ISO files"""
        files = filedialog.askopenfilenames(
            title="Select ISO files",
            filetypes=[("ISO files", "*.iso *.bin *.img"), ("All files", "*.*")]
        )
        
        for file_path in files:
            if file_path not in self.file_list:
                self.file_list.append(file_path)
                size = os.path.getsize(file_path)
                size_mb = f"{size / (1024*1024):.1f} MB"
                self.tree.insert("", "end", text=os.path.basename(file_path), 
                               values=(size_mb, "Waiting"))
        
        self.update_status(f"{len(self.file_list)} files selected")
    
    def clear_files(self):
        """Clear file list"""
        self.file_list.clear()
        for item in self.tree.get_children():
            self.tree.delete(item)
        self.update_status("File list cleared")
    
    def select_output_folder(self):
        """Select output folder"""
        folder = filedialog.askdirectory(title="Select output folder")
        if folder:
            self.output_folder.set(folder)
            self.update_status(f"Output folder: {folder}")
    
    def start_compression(self):
        """Start compression process"""
        if not self.file_list:
            messagebox.showerror("Error", "Please select at least one ISO file")
            return
        
        if not os.path.exists(self.output_folder.get()):
            messagebox.showerror("Error", "Output folder does not exist")
            return
        
        self.start_button.config(state="disabled")
        self.stop_button.config(state="normal")
        
        # Start compression in a separate thread
        self.compression_thread = threading.Thread(target=self.compress_files)
        self.compression_thread.daemon = True
        self.compression_thread.start()
    
    def stop_compression(self):
        """Stop compression process"""
        self.start_button.config(state="normal")
        self.stop_button.config(state="disabled")
        self.update_status("Compression stopped")
    
    def compress_files(self):
        """Compress files in separate thread"""
        total_files = len(self.file_list)
        completed = 0
        failed = 0
        
        for i, file_path in enumerate(self.file_list):
            # Update progress
            self.root.after(0, lambda: self.progress.config(value=(i/total_files)*100))
            
            # Update tree item status
            items = self.tree.get_children()
            if i < len(items):
                self.root.after(0, lambda item=items[i]: self.tree.set(item, "Status", "Processing..."))
            
            # Compress file
            success = self.compress_single_file(file_path)
            
            if success:
                completed += 1
                status = "Completed"
                if self.delete_input.get():
                    try:
                        os.remove(file_path)
                    except:
                        pass
            else:
                failed += 1
                status = "Failed"
            
            # Update tree item status
            if i < len(items):
                self.root.after(0, lambda item=items[i], st=status: self.tree.set(item, "Status", st))
            
            # Update status
            self.root.after(0, lambda: self.update_status(
                f"Progress: {i+1}/{total_files} - {completed} completed, {failed} failed"))
        
        # Final status
        self.root.after(0, lambda: self.update_status(
            f"Compression complete: {completed} successful, {failed} failed"))
        self.root.after(0, lambda: self.progress.config(value=100))
        self.root.after(0, lambda: self.start_button.config(state="normal"))
        self.root.after(0, lambda: self.stop_button.config(state="disabled"))
    
    def compress_single_file(self, file_path):
        """Compress a single file"""
        try:
            file_name = Path(file_path).stem
            
            if self.compression_type.get() == "CSO":
                output_file = os.path.join(self.output_folder.get(), f"{file_name}.cso")
                cmd = ["maxcso.exe", file_path, "-o", output_file]
            else:
                output_file = os.path.join(self.output_folder.get(), f"{file_name}.chd")
                cmd = ["chdman.exe", "createcd", "-i", file_path, "-o", output_file]
                if self.force_overwrite.get():
                    cmd.append("-f")
            
            # Execute command
            result = subprocess.run(cmd, capture_output=True, text=True)
            
            return result.returncode == 0 and os.path.exists(output_file)
            
        except Exception as e:
            print(f"Error compressing {file_path}: {e}")
            return False
    
    def update_status(self, message):
        """Update status bar"""
        self.status_var.set(message)
    
    def load_settings(self):
        """Load settings from file"""
        if os.path.exists(self.config_file):
            self.config.read(self.config_file)
    
    def save_settings(self):
        """Save settings to file"""
        if 'General' not in self.config:
            self.config.add_section('General')
        
        self.config.set('General', 'OutputFolder', self.output_folder.get())
        self.config.set('General', 'CompressionType', self.compression_type.get())
        
        with open(self.config_file, 'w') as f:
            self.config.write(f)
    
    def run(self):
        """Start the application"""
        self.root.protocol("WM_DELETE_WINDOW", self.on_closing)
        self.root.mainloop()
    
    def on_closing(self):
        """Handle application closing"""
        self.save_settings()
        self.root.destroy()

if __name__ == "__main__":
    app = UniversalCompressor()
    app.run()
