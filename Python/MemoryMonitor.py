#!/usr/bin/env python3
import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
import psutil
ram_usage = psutil.virtual_memory().percent
mail_content = 'Warning, server memory is running low!\n\nRam usage %' + str(ram_usage)
sender_address = 'xxxxxxxx@gmail.com'
sender_pass = 'password'
receiver_address = 'xxxxxxxx@gmail.com'
#Setup the MIME
message = MIMEMultipart()
message['From'] = sender_address
message['To'] = receiver_address
message['Subject'] = 'Memory Is Getting Low'   #The subject line
#The body and the attachments for the mail
message.attach(MIMEText(mail_content, 'plain'))
#Create SMTP session for sending the mail
if (float(ram_usage) > 80.0):
    session = smtplib.SMTP('smtp.gmail.com', 587) #use gmail with port
    session.starttls() #enable security
    session.login(sender_address, sender_pass) #login with mail_id and password
    text = message.as_string()
    session.sendmail(sender_address, receiver_address, text)
    session.quit()
else:
    quit()
