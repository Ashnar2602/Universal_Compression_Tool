#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Universal ISO Compression Tool - GUI
Simple and modern interface for ISO compression
"""

import sys
import os
import threading
import subprocess
from pathlib import Path
from typing import List, Optional
import tkinter as tk
from tkinter import ttk, filedialog, messagebox
import queue
import json

class CompressionGUI:
    def __init__(self):
        self.root = tk.Tk()
        self.root.title("Universal ISO Compression Tool")
        self.root.geometry("800x600")
        self.root.minsize(600, 400)
        
        # Configuration
        self.config = self.load_config()
        self.selected_files = []
        self.output_folder = tk.StringVar(value=self.config.get('output_folder', ''))
        self.format_var = tk.StringVar(value=self.config.get('format', 'cso'))
        self.threads_var = tk.IntVar(value=self.config.get('threads', 4))
        self.concurrent_files_var = tk.IntVar(value=self.config.get('concurrent_files', 1))
        
        # Progress tracking
        self.progress_queue = queue.Queue()
        self.is_compressing = False
        
        self.create_widgets()
        self.center_window()
        
    def load_config(self) -> dict:
        """Load configuration from JSON file"""
        config_file = Path(__file__).parent / "config.json"
        try:
            if config_file.exists():
                with open(config_file, 'r') as f:
                    return json.load(f)
        except Exception as e:
            print(f"Error loading config: {e}")
        return {}
    
    def save_config(self):
        """Save current configuration to JSON file"""
        config = {
            'output_folder': self.output_folder.get(),
            'format': self.format_var.get(),
            'threads': self.threads_var.get(),
            'concurrent_files': self.concurrent_files_var.get()
        }
        
        config_file = Path(__file__).parent / "config.json"
        try:
            with open(config_file, 'w') as f:
                json.dump(config, f, indent=2)
        except Exception as e:
            print(f"Error saving config: {e}")
    
    def center_window(self):
        """Center the window on screen"""
        self.root.update_idletasks()
        x = (self.root.winfo_screenwidth() // 2) - (self.root.winfo_width() // 2)
        y = (self.root.winfo_screenheight() // 2) - (self.root.winfo_height() // 2)
        self.root.geometry(f"+{x}+{y}")
    
    def create_widgets(self):
        """Create the main GUI widgets"""
        # Main frame
        main_frame = ttk.Frame(self.root, padding="10")
        main_frame.grid(row=0, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))
        
        # Configure grid weights
        self.root.columnconfigure(0, weight=1)
        self.root.rowconfigure(0, weight=1)
        main_frame.columnconfigure(1, weight=1)
        main_frame.rowconfigure(2, weight=1)
        
        # File selection section
        self.create_file_selection(main_frame)
        
        # Options section
        self.create_options_section(main_frame)
        
        # File list
        self.create_file_list(main_frame)
        
        # Progress section
        self.create_progress_section(main_frame)
        
        # Action buttons
        self.create_action_buttons(main_frame)
    
    def create_file_selection(self, parent):
        """Create file selection widgets"""
        # File selection frame
        file_frame = ttk.LabelFrame(parent, text="File Selection", padding="5")
        file_frame.grid(row=0, column=0, columnspan=2, sticky=(tk.W, tk.E), pady=(0, 10))
        file_frame.columnconfigure(1, weight=1)
        
        # Add files button
        ttk.Button(file_frame, text="Add Files...", 
                  command=self.add_files).grid(row=0, column=0, padx=(0, 5))
        
        # Add folder button
        ttk.Button(file_frame, text="Add Folder...", 
                  command=self.add_folder).grid(row=0, column=1, padx=5)
        
        # Clear button
        ttk.Button(file_frame, text="Clear All", 
                  command=self.clear_files).grid(row=0, column=2, padx=(5, 0))
        
        # Output folder selection
        ttk.Label(file_frame, text="Output Folder:").grid(row=1, column=0, sticky=tk.W, pady=(10, 0))
        
        output_frame = ttk.Frame(file_frame)
        output_frame.grid(row=2, column=0, columnspan=3, sticky=(tk.W, tk.E), pady=(5, 0))
        output_frame.columnconfigure(0, weight=1)
        
        self.output_entry = ttk.Entry(output_frame, textvariable=self.output_folder)
        self.output_entry.grid(row=0, column=0, sticky=(tk.W, tk.E), padx=(0, 5))
        
        ttk.Button(output_frame, text="Browse...", 
                  command=self.browse_output).grid(row=0, column=1)
    
    def create_options_section(self, parent):
        """Create compression options widgets"""
        options_frame = ttk.LabelFrame(parent, text="Compression Options", padding="5")
        options_frame.grid(row=1, column=0, columnspan=2, sticky=(tk.W, tk.E), pady=(0, 10))
        
        # Format selection
        ttk.Label(options_frame, text="Output Format:").grid(row=0, column=0, sticky=tk.W)
        format_frame = ttk.Frame(options_frame)
        format_frame.grid(row=0, column=1, sticky=tk.W, padx=(10, 0))
        
        ttk.Radiobutton(format_frame, text="CSO", variable=self.format_var, 
                       value="cso").grid(row=0, column=0, padx=(0, 10))
        ttk.Radiobutton(format_frame, text="CHD", variable=self.format_var, 
                       value="chd").grid(row=0, column=1)
        
        # Thread count
        ttk.Label(options_frame, text="CPU Threads:").grid(row=1, column=0, sticky=tk.W, pady=(10, 0))
        thread_frame = ttk.Frame(options_frame)
        thread_frame.grid(row=1, column=1, sticky=tk.W, padx=(10, 0), pady=(10, 0))
        
        ttk.Scale(thread_frame, from_=1, to=16, variable=self.threads_var, 
                 orient=tk.HORIZONTAL, length=200).grid(row=0, column=0)
        ttk.Label(thread_frame, textvariable=self.threads_var).grid(row=0, column=1, padx=(10, 0))
        
        # Concurrent files
        ttk.Label(options_frame, text="Concurrent Files:").grid(row=2, column=0, sticky=tk.W, pady=(10, 0))
        concurrent_frame = ttk.Frame(options_frame)
        concurrent_frame.grid(row=2, column=1, sticky=tk.W, padx=(10, 0), pady=(10, 0))
        
        ttk.Scale(concurrent_frame, from_=1, to=8, variable=self.concurrent_files_var, 
                 orient=tk.HORIZONTAL, length=200).grid(row=0, column=0)
        ttk.Label(concurrent_frame, textvariable=self.concurrent_files_var).grid(row=0, column=1, padx=(10, 0))
    
    def create_file_list(self, parent):
        """Create file list widget"""
        list_frame = ttk.LabelFrame(parent, text="Selected Files", padding="5")
        list_frame.grid(row=2, column=0, columnspan=2, sticky=(tk.W, tk.E, tk.N, tk.S), pady=(0, 10))
        list_frame.columnconfigure(0, weight=1)
        list_frame.rowconfigure(0, weight=1)
        
        # Treeview for file list
        columns = ('File', 'Size', 'Status')
        self.file_tree = ttk.Treeview(list_frame, columns=columns, show='headings', height=8)
        
        # Configure columns
        self.file_tree.heading('File', text='File')
        self.file_tree.heading('Size', text='Size')
        self.file_tree.heading('Status', text='Status')
        
        self.file_tree.column('File', width=400)
        self.file_tree.column('Size', width=100)
        self.file_tree.column('Status', width=100)
        
        # Scrollbars
        v_scrollbar = ttk.Scrollbar(list_frame, orient=tk.VERTICAL, command=self.file_tree.yview)
        h_scrollbar = ttk.Scrollbar(list_frame, orient=tk.HORIZONTAL, command=self.file_tree.xview)
        self.file_tree.configure(yscrollcommand=v_scrollbar.set, xscrollcommand=h_scrollbar.set)
        
        # Grid layout
        self.file_tree.grid(row=0, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))
        v_scrollbar.grid(row=0, column=1, sticky=(tk.N, tk.S))
        h_scrollbar.grid(row=1, column=0, sticky=(tk.W, tk.E))
    
    def create_progress_section(self, parent):
        """Create progress tracking widgets"""
        progress_frame = ttk.LabelFrame(parent, text="Progress", padding="5")
        progress_frame.grid(row=3, column=0, columnspan=2, sticky=(tk.W, tk.E), pady=(0, 10))
        progress_frame.columnconfigure(0, weight=1)
        
        # Progress bar
        self.progress_bar = ttk.Progressbar(progress_frame, mode='determinate')
        self.progress_bar.grid(row=0, column=0, sticky=(tk.W, tk.E), pady=(0, 5))
        
        # Status label
        self.status_label = ttk.Label(progress_frame, text="Ready")
        self.status_label.grid(row=1, column=0, sticky=tk.W)
    
    def create_action_buttons(self, parent):
        """Create action buttons"""
        button_frame = ttk.Frame(parent)
        button_frame.grid(row=4, column=0, columnspan=2, sticky=tk.E)
        
        self.start_button = ttk.Button(button_frame, text="Start Compression", 
                                      command=self.start_compression)
        self.start_button.grid(row=0, column=0, padx=(0, 5))
        
        self.stop_button = ttk.Button(button_frame, text="Stop", 
                                     command=self.stop_compression, state='disabled')
        self.stop_button.grid(row=0, column=1, padx=5)
        
        ttk.Button(button_frame, text="Exit", 
                  command=self.on_closing).grid(row=0, column=2, padx=(5, 0))
    
    def add_files(self):
        """Add individual files"""
        filetypes = [
            ('ISO files', '*.iso'),
            ('BIN files', '*.bin'),
            ('IMG files', '*.img'),
            ('All files', '*.*')
        ]
        
        files = filedialog.askopenfilenames(
            title="Select ISO files",
            filetypes=filetypes
        )
        
        for file_path in files:
            if file_path not in self.selected_files:
                self.selected_files.append(file_path)
                self.add_file_to_list(file_path)
    
    def add_folder(self):
        """Add all ISO files from a folder"""
        folder = filedialog.askdirectory(title="Select folder containing ISO files")
        if folder:
            extensions = ['.iso', '.bin', '.img']
            for ext in extensions:
                for file_path in Path(folder).glob(f"*{ext}"):
                    file_str = str(file_path)
                    if file_str not in self.selected_files:
                        self.selected_files.append(file_str)
                        self.add_file_to_list(file_str)
    
    def add_file_to_list(self, file_path: str):
        """Add a file to the treeview list"""
        try:
            size = Path(file_path).stat().st_size
            size_str = self.format_size(size)
            
            self.file_tree.insert('', 'end', values=(
                Path(file_path).name,
                size_str,
                'Pending'
            ))
        except Exception as e:
            print(f"Error adding file {file_path}: {e}")
    
    def format_size(self, size: int) -> str:
        """Format file size in human readable format"""
        for unit in ['B', 'KB', 'MB', 'GB']:
            if size < 1024.0:
                return f"{size:.1f} {unit}"
            size /= 1024.0
        return f"{size:.1f} TB"
    
    def clear_files(self):
        """Clear all selected files"""
        self.selected_files.clear()
        for item in self.file_tree.get_children():
            self.file_tree.delete(item)
    
    def browse_output(self):
        """Browse for output folder"""
        folder = filedialog.askdirectory(title="Select output folder")
        if folder:
            self.output_folder.set(folder)
    
    def start_compression(self):
        """Start the compression process"""
        if not self.selected_files:
            messagebox.showwarning("No Files", "Please select files to compress.")
            return
        
        if not self.output_folder.get():
            messagebox.showwarning("No Output", "Please select an output folder.")
            return
        
        self.is_compressing = True
        self.start_button.config(state='disabled')
        self.stop_button.config(state='normal')
        
        # Save configuration
        self.save_config()
        
        # Start compression in background thread
        thread = threading.Thread(target=self.compression_worker, daemon=True)
        thread.start()
        
        # Start progress monitoring
        self.monitor_progress()
    
    def stop_compression(self):
        """Stop the compression process"""
        self.is_compressing = False
        self.start_button.config(state='normal')
        self.stop_button.config(state='disabled')
        self.status_label.config(text="Stopped")
    
    def compression_worker(self):
        """Background worker for compression"""
        try:
            total_files = len(self.selected_files)
            completed = 0
            
            for file_path in self.selected_files:
                if not self.is_compressing:
                    break
                
                # Update status
                filename = Path(file_path).name
                self.progress_queue.put(('status', f"Compressing {filename}..."))
                
                # Create output filename
                output_ext = '.cso' if self.format_var.get() == 'cso' else '.chd'
                output_file = Path(self.output_folder.get()) / f"{Path(file_path).stem}{output_ext}"
                
                # Build command
                cmd = self.build_compression_command(file_path, str(output_file))
                
                # Execute compression
                result = self.execute_compression(cmd)
                
                completed += 1
                progress = (completed / total_files) * 100
                self.progress_queue.put(('progress', progress))
                
                # Update file status in list
                status = "Completed" if result else "Error"
                self.progress_queue.put(('file_status', filename, status))
            
            self.progress_queue.put(('finished', completed, total_files))
            
        except Exception as e:
            self.progress_queue.put(('error', str(e)))
    
    def build_compression_command(self, input_file: str, output_file: str) -> List[str]:
        """Build the compression command"""
        exe_path = Path(__file__).parent.parent / "bin" / "universal-compressor.exe"
        
        cmd = [
            str(exe_path),
            f"--type={self.format_var.get()}",
            f"--threads={self.threads_var.get()}",
            f"--input={input_file}",
            f"--output={output_file}"
        ]
        
        return cmd
    
    def execute_compression(self, cmd: List[str]) -> bool:
        """Execute the compression command"""
        try:
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=3600  # 1 hour timeout
            )
            return result.returncode == 0
        except Exception as e:
            print(f"Compression error: {e}")
            return False
    
    def monitor_progress(self):
        """Monitor progress from the worker thread"""
        try:
            while True:
                try:
                    message = self.progress_queue.get_nowait()
                    msg_type = message[0]
                    
                    if msg_type == 'status':
                        self.status_label.config(text=message[1])
                    elif msg_type == 'progress':
                        self.progress_bar['value'] = message[1]
                    elif msg_type == 'file_status':
                        self.update_file_status(message[1], message[2])
                    elif msg_type == 'finished':
                        self.compression_finished(message[1], message[2])
                        break
                    elif msg_type == 'error':
                        self.compression_error(message[1])
                        break
                        
                except queue.Empty:
                    break
        except:
            pass
        
        if self.is_compressing:
            self.root.after(100, self.monitor_progress)
    
    def update_file_status(self, filename: str, status: str):
        """Update the status of a file in the list"""
        for item in self.file_tree.get_children():
            values = self.file_tree.item(item, 'values')
            if values[0] == filename:
                self.file_tree.item(item, values=(values[0], values[1], status))
                break
    
    def compression_finished(self, completed: int, total: int):
        """Handle compression completion"""
        self.is_compressing = False
        self.start_button.config(state='normal')
        self.stop_button.config(state='disabled')
        self.status_label.config(text=f"Completed: {completed}/{total} files")
        
        if completed > 0:
            messagebox.showinfo("Compression Complete", 
                              f"Successfully compressed {completed} out of {total} files.")
    
    def compression_error(self, error_msg: str):
        """Handle compression error"""
        self.is_compressing = False
        self.start_button.config(state='normal')
        self.stop_button.config(state='disabled')
        self.status_label.config(text="Error occurred")
        messagebox.showerror("Compression Error", f"An error occurred: {error_msg}")
    
    def on_closing(self):
        """Handle window closing"""
        if self.is_compressing:
            if messagebox.askokcancel("Quit", "Compression is in progress. Do you want to quit?"):
                self.is_compressing = False
                self.root.destroy()
        else:
            self.save_config()
            self.root.destroy()
    
    def run(self):
        """Start the GUI"""
        self.root.protocol("WM_DELETE_WINDOW", self.on_closing)
        self.root.mainloop()

def main():
    """Main entry point"""
    app = CompressionGUI()
    app.run()

if __name__ == "__main__":
    main()
