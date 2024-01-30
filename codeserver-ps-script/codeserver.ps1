import socket, os, platform, subprocess

def main():
    hostname = socket.gethostname().lower()
    code_name="http://"+hostname+"-code.testfx/"
    app_name="http://"+hostname+"-app.testfx/"
    print("Code: " + code_name)
    print("App:  " + app_name)
    if platform.system() == "Windows":
        os.startfile(code_name)
        os.startfile(app_name)
    else:
        subprocess.call(("xdg-open", code_name))
        subprocess.call(("xdg-open", app_name))

if __name__ == "__main__":
    main()

